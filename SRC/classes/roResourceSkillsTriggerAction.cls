public with sharing class roResourceSkillsTriggerAction {

    public static void createUniqueId(List<Resource_skills__c> AllResourceSkills){      
        for (Resource_skills__c RS : AllResourceSkills){
            if(Schema.sObjectType.Resource_skills__c.fields.UniqueID__c.isUpdateable()){
              RS.UniqueID__c = string.valueof(RS.resource__c).substring(0,15) + string.valueof(RS.skill__c).substring(0,15) ;
            }     
        }
      }
      
    public static void UpdateResourceSkillsfield(List<Resource_skills__c> AllResourceSkills){
        Set<Id> ResourceIds = new Set<Id>();
        for (Resource_skills__c RS : AllResourceSkills){
            ResourceIds.add(RS.resource__C);
        }
        List<Resource_skills__c> OverallResourceSkills = new List<Resource_skills__c>();
        List<resource__C> Allresources = new List<resource__C>();
        if(Schema.sObjectType.Resource_skills__c.fields.resource__c.isAccessible()&&
        Schema.sObjectType.Resource_skills__c.fields.skill__c.isAccessible() &&
        Schema.sObjectType.Skills__c.fields.Active__c.isAccessible() ){
            OverallResourceSkills = [select id,resource__c,skill__c from Resource_skills__c where resource__c In :ResourceIds AND skill__r.Active__c = true];
        }

        if(Schema.sObjectType.resource__C.fields.Skills_backend__c.isAccessible()){
            Allresources = [select id,Skills_backend__c from resource__c where Id in :ResourceIds];
        }

        if(Allresources.size()>0){
            For(resource__C R : Allresources){
                String ResourceSkillsIDs = '';
                for(Resource_skills__c RSS : OverallResourceSkills){
                    if(string.valueof(RSS.resource__c).substring(0,15) == string.valueof(R.Id).substring(0,15)){
                    ResourceSkillsIDs += string.valueof(RSS.skill__c).substring(0,15)  +',';  
                    }
                }
                if(Schema.sObjectType.resource__C.fields.Skills_backend__c.isUpdateable()){
                    R.Skills_backend__c = ResourceSkillsIDs ;
                }                 
            }
        }
        
        try{
            if(Schema.sObjectType.resource__c.isUpdateable()){
                update Allresources ; 
            }
        }
        catch(exception e){
            if(Schema.sObjectType.Resource_Optimizer_Log__c.isCreateable() ){
                Database.insert(new Resource_Optimizer_Log__c( Error_Message__c = e.getMessage(),Event__c = 'Resource Skills Update',
                Exception_caught_by__c = UserInfo.getUserId()));
            }
        }
    }
}