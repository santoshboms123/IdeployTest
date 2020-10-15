/************************************************************************ 
Author : Sukku
Details: 
    Purpose : MobileCalendarHandler is the apex class to fetch the data from MobileCalendarConfig__mdt and return 
              a wrapper response to mobilecalendar Web component. 
    Intial release date : August 01, 2020 

Powered by Cloud Sloka Pty Ltd. "www.cloudsloka.com.au"
*************************************************************************/
public class roCalendarWrapper {
    
    @AuraEnabled public List<connectorObject> connectorObjectList {get; set;}

    public class connectorObject{
        @AuraEnabled public string objectAPIName {get; set;}
        @AuraEnabled public string objectLabel {get; set;}
        @AuraEnabled public List<connectorObjectData> objectData {get; set;}
        @AuraEnabled public List<recordTypesWrapper> objectRecordTypes {get; set;}
        @AuraEnabled public List<columnWrapper> columnMetadata {get; set;} 
    }

    public class connectorObjectData{
        @AuraEnabled public string recordId {get; set;}
        @AuraEnabled public string recordName {get; set;}
        @AuraEnabled public string description {get; set;}
        @AuraEnabled public string startDateTime {get; set;}
        @AuraEnabled public string endDateTime {get; set;}
        //@AuraEnabled public string filterData {get; set;}
        @AuraEnabled public List<columnWrapper> columns {get; set;}
    }

    //wrapper to store parent object info in json format
    public class resourceAllocationParentWrapper{
        @AuraEnabled public string objectAPIName {get; set;}
        @AuraEnabled public string objectLabel {get; set;}
        @AuraEnabled public string recordIdAPI {get; set;}
        @AuraEnabled public string recordNameAPI {get; set;}
        @AuraEnabled public string recordTypeId {get; set;}
        @AuraEnabled public string recordTypeName {get; set;}
        @AuraEnabled public string recordTypeDeveloperName {get; set;}
        @AuraEnabled public String startDateTimeFielAPI {get; set;}
        @AuraEnabled public String endDateTimeFielAPI {get; set;}
        @AuraEnabled public string descriptionFieldAPI {get; set;}
        @AuraEnabled public List<columnWrapper> columns {get; set;}
        @AuraEnabled public List<recordTypesWrapper> recordTypes {get; set;}
        @AuraEnabled public string soqlString {get; set;}
        @AuraEnabled public String filterString;

    }

    public class columnWrapper{
        @AuraEnabled public string fieldType {get; set;}
        @AuraEnabled public string fieldLabel {get; set;}//used while storing retrieving parent record metadata and while passing parent json to calendar
        @AuraEnabled public string fieldApiName {get; set;}//used while storing retrieving parent record metadata
        @AuraEnabled public string fieldValue {get; set;}//used while passing parent json to calendar
    }
    
    public class recordTypesWrapper{
        @AuraEnabled public string recordTypeId {get; set;}
        @AuraEnabled public string recordTypeName {get; set;}
        @AuraEnabled public string recordTypeDeveloperName {get; set;}
        @AuraEnabled public List<connectorObjectData> objectData {get; set;}
        @AuraEnabled public List<columnWrapper> columnMetadata {get; set;}
    }

    
    // Child Wrapper
    public class ResourceScheduleWrapper{
       @AuraEnabled public ResourceSchedule ResourceSchedule {get; set;}     
    }
    
    public class ResourceSchedule{
        @AuraEnabled public List<ResourceGroup> ResourceGroup;
    }
    
    public class ResourceGroup{
       @AuraEnabled public String Groupname;
       @AuraEnabled public List<ChildGroup> ChildGroup;
       @AuraEnabled public List<Resource> Resource;
    }
    
    public class ChildGroup{
       @AuraEnabled public String Groupname;
       @AuraEnabled public List<ChildGroup> ChildGroup;
       @AuraEnabled public List<Resource> Resource;
    }
    
    public class Resource{
       @AuraEnabled public String ResourceID;
       @AuraEnabled public String ResourceName;
       @AuraEnabled public String ResourceRole;
       @AuraEnabled public String ResourceSkills; 
       @AuraEnabled public String ProfileImageURL;
       //@AuraEnabled public Integer Maxheight;
       @AuraEnabled public String WeeklyUtilization;
       @AuraEnabled public AssignedRecords AssignedRecords;
       @AuraEnabled public List<AvailableDateTimes> AvailableDateTimes;
    }
    
    public class AssignedRecords{
      @AuraEnabled  public List<Day> Day;
    }
    
    public class Day{
       @AuraEnabled public String CurrentDate;
       @AuraEnabled public String StartDatetime;
       @AuraEnabled public String EndDatetime;
       @AuraEnabled Public String Utilization;
       @AuraEnabled public List<Record> Record;
       @AuraEnabled public List<AvailableDateTimes> AvailableDateTimes;
    }

    public class AvailableDateTimes{
        @AuraEnabled public String StartDatetime;
        @AuraEnabled public String EndDatetime;
    }
    
    public class Record {
       @AuraEnabled public String Recordtype;
       @AuraEnabled public String RecordApiName;
       @AuraEnabled public String Recordid;
       @AuraEnabled public String Recordstartdate;
       @AuraEnabled public String RecordEnddate;
       @AuraEnabled public String Recordname;
       @AuraEnabled public String Recordcolor;
    }
}