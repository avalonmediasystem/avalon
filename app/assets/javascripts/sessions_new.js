$( document ).ready(function() {
  $(document).on('click', 'a[data-trigger="show-email"]', function(event){
    $('#email-box').toggleClass('hidden')
    $('#sign-in-select').toggleClass('hidden')
    $('#sign-in-buttons').toggleClass('hidden')
  })
  let searchParams = new URLSearchParams(window.location.search)
  if(searchParams.has('email')){
    $('#email-box').toggleClass('hidden')
    $('#sign-in-select').toggleClass('hidden')
    $('#sign-in-buttons').toggleClass('hidden')
  }
})
