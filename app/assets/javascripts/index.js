Redface = (function() {
  var Redface = {};
  function loginFromAuthResponse(authResponse) {
    if (authResponse && authResponse.accessToken) {
      console.log('Got valid accessToken');
      Redface.loginResponse = authResponse;
      Redface.viewerFbuid = authResponse.userID;
      $('#fb-login-wrapper').hide();
      $('#spinner').show();
      loadStream();
    } else {
      console.log('no valid accessToken');
    }
  }

  function init() {
    $('#show_new_stories').on('click', function(e) {
      e.preventDefault();
      var $importComplete = $('#import_complete');
      $('#content').empty().append($importComplete.data('stories'));
      $importComplete.hide();
    });

    var authResponse = FB.getAuthResponse();
    if (authResponse && authResponse.accessToken) {
      // already logged in with an active token
      console.log('already logged in');
      loginFromAuthResponse(authResponse);
    } else {
      // not logged in
      console.log('not logged in');
      FB.Event.subscribe('auth.authResponseChange', function(response) {
        loginFromAuthResponse(response.authResponse);
      });
    }
  }

  function loadStream() {
    console.log('enter loadStream');
    $.ajax({
      url : '/stories?fbuid=' + Redface.viewerFbuid,
      dataType : 'json',
      complete : function(resp) {
        var respJson = JSON.parse(resp.responseText);
        console.log('loadStream resp', resp);
        if ($('li').length === 0) {
          $('#spinner').hide();
          $('#content').append(respJson.html);
        }
        importStream();
      }
    });
  }

  function importStream() {
    console.log('enter importStream');
    console.log('sending data: ', Redface.loginResponse);
    $.ajax({
      url      : '/import',
      data     : Redface.loginResponse,
      dataType : 'json',
      complete  : function(resp) {
        var respJson = JSON.parse(resp.responseText);
        if ($('li').length == 0) {
          $('#content').append(respJson.html);
          $('#spinner').hide();
        } else {
          $('#import_complete').show().data('stories', respJson.html);
        }
      }
    });
  }

  return { init : init };
})();
