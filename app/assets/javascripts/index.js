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
        if ($('li').length == 0) {
          $('#content').append(respJson.html);
        }
        if (respJson.count == 0) {
          // only refresh if the page is empty
          importStream(true);
        } else {
          $('#spinner').hide();
        }
      }
    });
  }

  function importStream(refresh) {
    console.log('enter importStream');
    console.log('sending data: ', Redface.loginResponse);
    $.ajax({
      url      : '/import',
      data     : Redface.loginResponse,
      dataType : 'json',
      complete  : function(resp) {
        var respJson = JSON.parse(resp.responseText);
        console.log("finished importStream", resp.responseText);
        if ($('li').length == 0) {
          $('#content').append(respJson.html);
          $('#spinner').hide();
        }
      }
    });
  }

  return { init : init };
})();
