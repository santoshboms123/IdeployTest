@isTest
public class roSignatureHandler_Test extends roTestDataFactory {
    
    testmethod static void roprofilepicturetest(){
        ResourceOptimizerConfig__c config = new ResourceOptimizerConfig__c(Resource_Start_Hours__c = 9, Resource_Start_Minutes__c = 0, 
                Resource_End_Hours__c = 17, Resource_End_Minutes__c = 0);
            insert config;
         String fileData = 'I am String';
        String fileDateBase64 = EncodingUtil.base64Encode(Blob.valueOf(fileData));
        String mimetype = 'text/csv;base64,';
        String fileName = 'SampleTest.csv';
        
        List<Resource__c> R =  createresourceswithdefaultparent(1);
        Resource_Allocation__c RA = new Resource_Allocation__c(Allocated_Start_DateTime__c = system.now() , Allocated_End_Datetime__c = system.now() + 30 , Resource__c = R[0].id ); 
        insert RA;
    	roSignatureHandler.saveSign(fileDateBase64, mimetype,RA.id);
        
        Attachment A = [select id,parentid,name from Attachment LIMIT 1];
        
        system.assert(A.parentid == RA.id);
            
       }


}