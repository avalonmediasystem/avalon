window.UserSelectBox =
  class UserSelectBox
    constructor: (@url, @selections) ->
      $('#managers').select2
        placeholder: 'Search by name or id'
        minimumInputLength: 7
        multiple: true
        width: '500px'

        initSelection: (element, callback) =>
          callback @selections
        ajax:
          url: @url
          dataType: 'json'
          data: (term, page) ->
            q: term
          results: (data, page) ->
            results:
              data.users


window.CollectionSelectBox =
  class CollectionSelectbox
    constructor: (@selector, @url, @collectionSelections) ->
      $(@selector).select2
        placeholder: 'Search by collection name'
        minimumInputLength: 3
        width: '500px'
        multiple: true
        # formatSelection: (collection, container) ->

        #   #$(container).empty().addClass('inner').append $( @renderTemplate collection )
        #   undefined
        formatResult: (collection) ->
          collection.text unless collection.thumbnail_url?
          @renderTemplate collection
        initSelection: (element, callback) =>
          callback @collectionSelections 
        ajax:
          url: @url
          dataType: 'json'
          data: (term, page) ->
            q: term
          results: (data, page) ->
            results:
              data.collections              
        renderTemplate: (collection) ->
          """<b>#{collection.text}</b>"""
window.MediaObjectSelectBox =
  class MediaObjectSelectBox
    constructor: (@url, @mediaSelections) ->
      $('#collection_media_object_ids').select2
        placeholder: 'Search by name or net id'
        minimumInputLength: 3
        multiple: true
        width: '500px'

        formatSelection: (mediaObject, container) ->
          $(container).empty().addClass('inner').append $( @renderTemplate mediaObject )
          undefined
        formatResult: (mediaObject) ->
          mediaObject.text unless mediaObject.thumbnail_url?
          @renderTemplate mediaObject
        initSelection: (element, callback) =>
          callback @mediaSelections
        ajax:
          url: @url
          dataType: 'json'
          data: (term, page) ->
            q: term
          results: (data, page) ->
            results:
              data.media_objects

        renderTemplate: (mediaObject) ->
          """
          <div class="" style="float: left;">
            <img class='media-object img-circle' src="#{mediaObject.thumbnail_url}"/>
          </div>

          <div class="caption">
            <h4>#{mediaObject.text}</h4>
            <div class='clearfix'/>
          </div>
          """