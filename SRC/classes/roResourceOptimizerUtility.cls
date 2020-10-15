/************************************************************************ 
Author : Santosh
Details: 
    Purpose : roResourceOptimizerUtility is a Utility Class to fetch Generic information and perform repetitive activities. 
    Intial release date : August 01, 2020 

Powered by Cloud Sloka Pty Ltd. "www.cloudsloka.com.au"
*************************************************************************/
public without sharing class roResourceOptimizerUtility {

    @AuraEnabled    
    public static Resource_allocation__c getallocation(Id Aid){

        String sObjName = Aid.getSObjectType().getDescribe().getName();

        if( sObjName == 'Resource_Allocation__c'){
            if(roSecurityHandler.checkField(new String[] {'name','Allocated_Start_DateTime__c','Type__c','Resource__c','Allocated_End_Datetime__c','Status__c','Street__c','City__c','PostalCode__c','Country__c','subject__c','description__c','Relatedto_Id__c','Relatedto_Name__c','Relatedto_Object__c'},'Resource_allocation__c',roSecurityHandler.permissionLevel.ISACCESSIBLE)){
                return [select id,name,Allocated_Start_DateTime__c,Resource__c,Type__c,Allocated_End_Datetime__c,Status__c,Street__c,City__c,Province__c,PostalCode__c,Country__c,subject__c,description__c,Relatedto_Id__c,Relatedto_Name__c,Relatedto_Object__c from Resource_allocation__c where id= :Aid LIMIT 1];
          }else{
                  return null;
              }       
  
          }
        else{
            return null;
        }
    }

    @AuraEnabled    
    public static Resource__c getresource(string Uid){

	if(roSecurityHandler.checkField(new String[] {'User__c','Active__c'},'Resource__c',roSecurityHandler.permissionLevel.ISACCESSIBLE)){
              return [select id,User__c from Resource__c where User__c= :Uid AND Active__c = true LIMIT 1];
        }else{
                return null;
            }       

     }

    public static Set<String> getFieldsFromObject(string objectAPIName, string fieldType, boolean customFIeldsOnly){
        try{
            Map <String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
            Map <String, Schema.SObjectField> fieldMap = schemaMap.get(objectAPIName).getDescribe().fields.getMap();
            Set<string> fieldAPINames = new Set<string>();
            for(Schema.SObjectField sfield : fieldMap.Values()){
                schema.describefieldresult dfield = sfield.getDescribe();
                string currentFieldType = string.valueOf(dfield.getType());
                if(customFIeldsOnly){
                    if(dfield.isCustom()){
                        if(String.isBlank(fieldType) ? true : fieldType == currentFieldType){
                            fieldAPINames.add(dfield.getname());
                        }
                    }
                }
                else{
                    if(String.isBlank(fieldType) ? true : fieldType == currentFieldType){
                        fieldAPINames.add(dfield.getname());
                    }
                }
            }
            return fieldAPINames;
        }
        catch(exception ex){
            //log exception
            logExceptionMessage(ex.getMessage(), 'get field api names', ex.getStackTraceString());
            return null;
        }
    }

    public static void logExceptionMessage(string errorMessage, string event, string stacktrace){
        if(Resource_Optimizer_Log__c.sObjectType.getDescribe().isCreateable()){
            Database.insert(new Resource_Optimizer_Log__c(
                Error_Message__c = errorMessage,
                Event__c = event,
                Stack_Trace__c = stacktrace,
                Exception_caught_by__c = UserInfo.getUserId()
            ));
        }
    }


}