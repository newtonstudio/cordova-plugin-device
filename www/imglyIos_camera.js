var ImglyIosCamera = {
getPicture: function(success, failure){
    
    cordova.exec(success, failure, "ImglyIosCamera", "openCamera", []);
}
};