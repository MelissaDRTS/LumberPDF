({
    init: function (component, event, helper) {
		helper.getObjectType(component, event, helper);
    },
    
    handleUploadFinished: function (component, event, helper) {
        var uploadedFiles = event.getParam("files");
        var documentId = uploadedFiles[0].documentId;
        var fileName = uploadedFiles[0].name;
        var fileType = component.get("v.fileName");
        var serviceRequestId = component.get('v.recId');
        var time = new Date();
        var year = time.getFullYear();
        var month = time.getMonth();
        month = month + 1;
        var day = time.getDate();
        var hour = time.getHours();
        var min = time.getMinutes();
        var sec = time.getSeconds();
        var timestamp = String(month) + String(day) + String(year) + "_" + String(hour) + String(min) + String(sec);
        var newFileName = "Signed_" + fileType + "_" + timestamp;

        console.log("Files uploaded : " + uploadedFiles.length);

        var fileObject = {
            documentId: documentId,
            fileType: fileType,
            newFileName: newFileName,
        };
        
        console.log(fileObject);
        helper.renameFile(component, fileObject);
        helper.updateSalesOrder(component, fileType);
    },
    
    handleChange: function (component, event, helper) {
        var selectedOptionValue = event.getParam("value");
        component.set('v.fileName', selectedOptionValue);
        
    },
    
    
})