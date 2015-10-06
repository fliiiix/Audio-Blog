var $ = function (id) { return document.getElementById(id); };

//fancy file selecter
function enableUpload() {
  var uploadInput = document.getElementById('uploadInput');
  if (uploadInput.value != ''){
    document.getElementById('uploadDiv').style.display = 'none';
    document.getElementById('selectedFileDiv').style.display = '';
     
    //remove span content and add the file name
    var filenameSpan = document.getElementById('filename');
    while( filenameSpan.firstChild ) {
      filenameSpan.removeChild( filenameSpan.firstChild );
    }
    filenameSpan.appendChild( document.createTextNode(uploadInput.value) );
  }
}
   
function selectNewFile() {
  document.getElementById('uploadDiv').style.display = '';
  document.getElementById('selectedFileDiv').style.display = 'none';
  document.getElementById('uploadInput').value = '';
}

//switch between url and file
function useURL () {
  $('soundcloudURL').style.display = '';
  $('uploadDiv').style.display = 'none';
  $('selectedFileDiv').style.display = 'none';
  $('uploadInput').value = ''
  $('useSoundcloudurl').style.display = 'none';
}
function useFile () {
  $('soundcloudURL').style.display = 'none';
  $('uploadDiv').style.display = '';
  $('useSoundcloudurl').style.display = '';
}