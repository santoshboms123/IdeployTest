/************************************************************************ 
Author : Sukku
Details: 
    Purpose : MobileCalendarHandler is the apex class to fetch the data from MobileCalendarConfig__mdt and return 
              a wrapper response to mobilecalendar Web component. 
    Intial release date : August 01, 2020 

Powered by Cloud Sloka Pty Ltd. "www.cloudsloka.com.au"
*************************************************************************/
public class roParentCreateOREditController {
   
    @AuraEnabled
    Public Static List<string> getAllObjects(){
        List<string> SObjectList = new List<string>();
        SObjectList.add('');
        Map<String , Schema.SObjectType> globalDescription = Schema.getGlobalDescribe();
        Schema.sObjectType objType = globalDescription.get('Resource_Allocation__c'); 
        Schema.DescribeSObjectResult r1 = objType.getDescribe(); 
        set<string> referenceFieldsToBeIgnored = new set<String>{'createdbyid','lastmodifiedbyid','ownerid','reservation__c', 'resource__c' };
        Map<String , Schema.SObjectField> mapFieldList = r1.fields.getMap();  
        for(Schema.SObjectField field : mapFieldList.values())  {  
            Schema.DescribeFieldResult fieldResult = field.getDescribe(); 
            if(fieldResult.isAccessible() && string.valueOf(fieldResult.getType()) == 'REFERENCE' && !referenceFieldsToBeIgnored.contains(fieldResult.getName().toLowerCase()) )  {  
               // SObjectList.add(fieldResult.getName());
                for(Schema.SObjectType reference : fieldResult.getReferenceTo()) {
                     System.debug('getName ==> ' + reference.getDescribe().getName());
                     SObjectList.add(reference.getDescribe().getName());
                }
            }  
        }
        SObjectList.add('Resource_Allocation__c');
        SobjectList.sort();
        return SObjectList ; 
    }
    
    @AuraEnabled
    public static List<String> objectFields(String selectedObject){
        List<String> fields = new List<String>();
        Map<String , Schema.SObjectType> globalDescription = Schema.getGlobalDescribe();
        Schema.sObjectType objType = globalDescription.get(selectedObject); 
        Schema.DescribeSObjectResult r1 = objType.getDescribe(); 
        
        Map<String , Schema.SObjectField> mapFieldList = r1.fields.getMap();  
        
        for(Schema.SObjectField field : mapFieldList.values())  {  
            Schema.DescribeFieldResult fieldResult = field.getDescribe();  
            
            if(fieldResult.isAccessible())  {  
                fields.add(fieldResult.getName());
            }  
        }
        List<String> so = new List<String>();
        for(String fs : fields){
            so.add(fs);
            so.sort();
        } 
        System.debug('so---->>' + so);
        return so;
    }
    
    @AuraEnabled
    public static List<String> objectDatetimeFields(String selectedObject){
        List<String> fields = new List<String>();
        Map<String , Schema.SObjectType> globalDescription = Schema.getGlobalDescribe();
        Schema.sObjectType objType = globalDescription.get(selectedObject); 
        Schema.DescribeSObjectResult r1 = objType.getDescribe(); 
        
        Map<String , Schema.SObjectField> mapFieldList = r1.fields.getMap();  
        
        for(Schema.SObjectField field : mapFieldList.values())  {  
            Schema.DescribeFieldResult fieldResult = field.getDescribe();  
            
            if(fieldResult.isAccessible() && (string.valueOf(fieldResult.getType()) == 'Date' || string.valueOf(fieldResult.getType()) == 'DateTime'))  {  
                fields.add(fieldResult.getName());
            }  
        }
        List<String> so = new List<String>();
        so.add('');
        for(String fs : fields){
            so.add(fs);
            so.sort();
        } 
        System.debug('so---->>' + so);
        return so; 
    }
    
    @AuraEnabled
    public static List<String> objectTextFields(String selectedObject){
        List<String> fields = new List<String>();
        Map<String , Schema.SObjectType> globalDescription = Schema.getGlobalDescribe();
       
        Schema.sObjectType objType = globalDescription.get(selectedObject); 
        Schema.DescribeSObjectResult sObjectResult = objType.getDescribe(); 
        Map<String , Schema.SObjectField> mapFieldList = sObjectResult.fields.getMap(); 
        
        // add blank value to the fieldlist
        fields.add('');
        // get all string fields in the object
        for(Schema.SObjectField field : mapFieldList.values())  {  
            Schema.DescribeFieldResult fieldResult = field.getDescribe();  
            if(fieldResult.isAccessible() && ((string.valueOf(fieldResult.getType()) == 'STRING') || (string.valueOf(fieldResult.getType()) == 'PICKLIST')))  {  
                fields.add(fieldResult.getName());
                fields.sort();
            }  
        }
        
        system.debug('text fieldlist ==> ' + fields);
        return fields;
    }
    
    @AuraEnabled
    public static List<String> objectRecordTypes(String selectedObject){
        List<String> lstRecordTypes = new List<String>();
        Map<String , Schema.SObjectType> globalDescription = Schema.getGlobalDescribe();
        Schema.sObjectType objType = globalDescription.get(selectedObject); 
        Schema.DescribeSObjectResult sObjectResult = objType.getDescribe(); 
        Map<Id,Schema.RecordTypeInfo> rtMapById = sObjectResult.getRecordTypeInfosById();
        lstRecordTypes.add('');
        for(Schema.RecordTypeInfo rti : sObjectResult.getRecordTypeInfos()) {
            if(rti.isActive() && rti.isAvailable()) {
                lstRecordTypes.add(rti.getDeveloperName());
                lstRecordTypes.sort();
            }
        }
        return lstRecordTypes;
    }
    
    @AuraEnabled
    public static Boolean validatesoql(String soqlstring){
        try{
            List<sobject> testQueryresult = database.query(soqlstring);
            return true;
        }catch(exception e){
            return false;
        }
    }
   
    @AuraEnabled
    public static roCalendarWrapper.resourceAllocationParentWrapper getCurrentData(Id raParentId){
        try{
            Resource_Allocation_Parent__c RAP = [SELECT Id, Parent_API_Name__c, Parent_JSON__c FROM Resource_Allocation_Parent__c WHERE Id = :raParentId]; 
            roCalendarWrapper.resourceAllocationParentWrapper parentWrapper = (roCalendarWrapper.resourceAllocationParentWrapper) JSON.deserialize(RAP.Parent_JSON__c, roCalendarWrapper.resourceAllocationParentWrapper.Class);
            system.debug('parentWrapper '+parentWrapper.filterString);
            return parentWrapper;
        }
        catch(exception ex){
            roResourceOptimizerUtility.logExceptionMessage(ex.getMessage(), 'get existing resource allocation parent data ', ex.getStackTraceString());
            return null;
        }
    }
     
    @AuraEnabled
    public static string saveRAParent(Id recordId, String sobjectAPIname, string soqlquerystring,string soqlfilterstring, List<string> fieldapinames, string startdateapiname, string enddateapiname, string recordNameAPI, String selectedRecordTypes ){
        try{
            List<Schema.DescribeSObjectResult> describeSobjectsResult = Schema.describeSObjects(new List<String>{sobjectAPIname});
           
            String objectLabel = describeSobjectsResult[0].getLabel();
            Map<String, Schema.SObjectField> allFields = describeSobjectsResult[0].fields.getMap();
            Map<String,Schema.RecordTypeInfo> rtMapByDeveloperName = describeSobjectsResult[0].getRecordTypeInfosByDeveloperName(); //getRecordTypeInfosByName();
            
            roCalendarWrapper.resourceAllocationParentWrapper RAParent = new roCalendarWrapper.resourceAllocationParentWrapper();
            List<roCalendarWrapper.columnWrapper> RC = new List<roCalendarWrapper.columnWrapper>() ; 
            List<roCalendarWrapper.recordTypesWrapper> listRTWrapper = new List<roCalendarWrapper.recordTypesWrapper>() ;  
              
            system.debug('rtMapDeveloperName ==> ' + rtMapByDeveloperName);
            system.debug('selectedRecordTypes ==> ' +  selectedRecordTypes);
            
            RAParent.objectLabel = objectLabel ;
            RAParent.objectAPIName = sobjectAPIname ;
            RAParent.soqlString = soqlquerystring ;
            RAParent.filterString = soqlfilterstring;
            RAParent.startDateTimeFielAPI = startdateapiname ;
            RAParent.endDateTimeFielAPI = enddateapiname ;
            RAParent.recordIdAPI = 'Id';
            RAParent.recordNameAPI = recordNameAPI;
             // add RecordTypes
            system.debug('rid ==> ' + rtMapByDeveloperName.containsKey(selectedRecordTypes));
            //system.debug('rname ==> ' + rtMapByDeveloperName.get(selectedRecordTypes).getName);
            RAParent.recordTypeId = selectedRecordTypes!=null && selectedRecordTypes!='' ? string.valueOf(rtMapByDeveloperName.get(selectedRecordTypes).RecordTypeId) : null;
            RAParent.recordTypeName = selectedRecordTypes!=null && selectedRecordTypes!='' ? string.valueOf(rtMapByDeveloperName.get(selectedRecordTypes).Name) : null;
            RAParent.recordTypeDeveloperName = selectedRecordTypes!=null && selectedRecordTypes!='' ? selectedRecordTypes : null;
            
            
          /*  roCalendarWrapper.recordTypesWrapper rtWrapper = new roCalendarWrapper.recordTypesWrapper();
            rtWrapper.recordTypeId = string.valueOf(rtMapByDeveloperName.get(selectedRecordTypes).RecordTypeId);
            rtwrapper.recordTypeDeveloperName = selectedRecordTypes;
            listRTWrapper.add(rtwrapper);
            RAParent.recordTypes = listRTWrapper ;*/
            
            // add Id as a default column
            roCalendarWrapper.columnWrapper defaultColId = new roCalendarWrapper.columnWrapper();
            defaultColId.fieldApiName = 'Id';
            defaultColId.fieldLabel = allFields.get('Id').getDescribe().getLabel();
            defaultColId.fieldType = string.valueOf(allFields.get('Id').getDescribe().getType());
            RC.add(defaultColId);
            
            // add name field
            roCalendarWrapper.columnWrapper defaultColName = new roCalendarWrapper.columnWrapper();
            defaultColName.fieldApiName = recordNameAPI;
            defaultColName.fieldLabel = allFields.get(recordNameAPI).getDescribe().getLabel();
            defaultColName.fieldType = string.valueOf(allFields.get(recordNameAPI).getDescribe().getType());
            RC.add(defaultColName);
           
            for(integer i = 0; i < fieldapinames.size(); i++){
                roCalendarWrapper.columnWrapper Col = new roCalendarWrapper.columnWrapper();
                col.fieldApiName = fieldapinames[i];
                col.fieldLabel = allFields.get(fieldapinames[i]).getDescribe().getLabel();
                col.fieldType = string.valueOf(allFields.get(fieldapinames[i]).getDescribe().getType());
                // col.fieldValue = '';
                system.debug(col);
                RC.add(col);
            }
            RAParent.columns = RC ;

            
            string jsonstring = JSON.serializePretty(RAParent);
            Resource_Allocation_Parent__c RAP = new Resource_Allocation_Parent__c(Id = recordId, Parent_API_Name__c = sobjectAPIname,name = objectLabel+'-'+selectedRecordTypes,Parent_JSON__c = jsonstring ); 
            upsert RAP;   
            
            return string.valueOf(RAP.id); 
        }
        catch(exception ex){
            system.debug('ERROR saving Resource Parent '+ex.getMessage());
            throw new AuraHandledException('ERROR saving Resource Parent: '+ex.getMessage());
        }
        
    }
    
    
}