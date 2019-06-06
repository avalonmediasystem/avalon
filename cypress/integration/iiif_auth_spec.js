const fixture = "manifest.json"
const hostname = "https://spruce.dlib.indiana.edu"
const username = "FILL_ME_IN"
const password = "FILL_ME_IN"
const loginFormTarget = hostname + "/users/auth/identity/callback"
const loginFormParams = { auth_key: username, password: password }

describe("IIIF Auth", function() {
  // Load the fixture into a global variable
  var iiif_manifest = null
  var stream = null
  var stream_url = null
  var auth_service = null
  var token_service = null
  var token_service_url = null

  beforeEach(function () {
    cy.fixture(fixture).then((manifest) => {
      iiif_manifest = manifest
      stream = iiif_manifest.items[0].items[0].items[0].body.items[0]
      stream_url = stream.id
      auth_service = stream.service[0]
      token_service = auth_service.service[0]
      token_service_url = token_service['@id'] + "?messageId=1&origin=" + hostname
    })
  })

  it('is a valid manifest', function(){
    expect(auth_service.context).to.eq("http://iiif.io/api/auth/1/context.json")
    expect(auth_service["@type"]).to.eq("AuthCookieService1")
    expect(token_service['@type']).to.eq('AuthTokenService1')
  })

  it("does the IIIF Auth Flow", function(){
    // HEAD request to stream_url -> expect 401
    cy.request({method: "HEAD", url: stream_url, failOnStatusCode: false}).then((resp) => {
      expect(resp.status).to.eq(401)
    })

    // Go ahead and submit the login form without actually going to the page.
    // Still need to test taht the window.close() happens after successful login.
    cy.request({method: "GET", url: auth_service["@id"]})
    cy.request({method: "POST", url: loginFormTarget, form: true, body: loginFormParams}).then((resp) => {
      expect(resp.status).to.eq(200)
      expect(cy.getCookie('_session_id')).to.exist
      expect(resp.body).to.include('window.close()')
    })

    // Receive postMessage and store token
    var postMessage = null
    var accessToken = ''
    cy.visit(token_service_url, {
      onBeforeLoad(win){postMessage = cy.spy(win.parent, 'postMessage').as('postMessage')}
    }).then((win) => {
      expect(postMessage).to.be.called
      accessToken = postMessage.args[0][0]['accessToken']
      expect(accessToken).to.exist
    })

    // Pass token to another request to content resource and expect 200
    cy.request({method: "HEAD", url: stream_url, failOnStatusCode: false,  'auth': { 'bearer': accessToken } }).then((resp) => {
      expect(resp.status).to.eq(200)
    })
    cy.request({method: "GET", url: stream_url, failOnStatusCode: false }).then((resp) => {
      expect(resp.status).to.eq(200)
    })
  })
})
