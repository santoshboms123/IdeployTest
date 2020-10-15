/************************************************************************ 
Author : Sukku
Details: 
    Purpose : MobileCalendarHandler is the apex class to fetch the data from MobileCalendarConfig__mdt and return 
              a wrapper response to mobilecalendar Web component. 
    Intial release date : August 01, 2020 

Powered by Cloud Sloka Pty Ltd. "www.cloudsloka.com.au"
*************************************************************************/

public with sharing class roCalendarController{
    
    @AuraEnabled
    public static roCalendarWrapper getConnectObjectDataNew(){
        try{
            List<Sobject> parentObjectDataCombined = new List<Sobject>();
            roCalendarWrapper calendarWrapper  = new roCalendarWrapper();
            List<roCalendarWrapper.connectorObject> connectorObjectList = new List<roCalendarWrapper.connectorObject>();
            map<string, roCalendarWrapper.connectorObject> mapConnectorObject = new map<string, roCalendarWrapper.connectorObject>();
            
            for(Resource_Allocation_Parent__c raParent :[SELECT Id, Parent_API_Name__c, Parent_JSON__c FROM Resource_Allocation_Parent__c]){
                if(!String.isBlank(raParent.Parent_JSON__c)){
                    roCalendarWrapper.resourceAllocationParentWrapper raParentWrapper = (roCalendarWrapper.resourceAllocationParentWrapper) JSON.deserialize(raParent.Parent_JSON__c, roCalendarWrapper.resourceAllocationParentWrapper.class);
                    List<sobject> parentRecs = Database.query(raParentWrapper.soqlString);
                    parentObjectDataCombined.addAll(parentRecs);
                    roCalendarWrapper.connectorObject connectObject = createWrapperforCalendarNew(raParentWrapper, parentRecs, mapConnectorObject.values());
                    system.debug('connectObject apiname ==> ' + connectObject.objectAPIName);
                    mapConnectorObject.put(connectObject.objectAPIName, connectObject);
                    //connectorObjectList.addAll(mapConnectorObject.values());
                }
            }
            calendarWrapper.connectorObjectList = mapConnectorObject.values();
            //system.debug('calendarWrapper ==> '+ JSON.serialize(calendarWrapper));
            return calendarWrapper;
        }
        catch(exception ex){
            //log exception in log object 
            system.debug('ERROR getting data '+ex.getMessage()+' at '+ex.getStackTraceString());
            return null;
        }
        
    }
    
    public static roCalendarWrapper.connectorObject createWrapperforCalendarNew(roCalendarWrapper.resourceAllocationParentWrapper raParentWrapper, List<Sobject> connectObjectData, List<roCalendarWrapper.connectorObject> connectorObjectList){
        
        try{
            roCalendarWrapper.connectorObject currentConnectorObject = new roCalendarWrapper.connectorObject();
            List<roCalendarWrapper.connectorObjectData> connectObjectDataList = new List<roCalendarWrapper.connectorObjectData>();
            List<roCalendarWrapper.recordTypesWrapper> connectObjectRTList = new List<roCalendarWrapper.recordTypesWrapper>();
            currentConnectorObject.objectLabel = raParentWrapper.objectLabel;
            currentConnectorObject.objectAPIName = raParentWrapper.objectAPIName;
            currentConnectorObject.columnMetadata = raParentWrapper.columns;
            boolean isTheSameConnectorObject = false;
            system.debug('connectorObjectList size() ==> ' + connectorObjectList.size());
            
            if(connectorObjectList.size()>0){
                for(roCalendarWrapper.connectorObject co: connectorObjectList){
                    if(co.objectAPIName == raParentWrapper.objectAPIName){
                        isTheSameConnectorObject = true;
                        currentConnectorObject = co;
                        system.debug('co.objectAPIName1 ==> ' +  co.objectAPIName + ' == ' + raParentWrapper.objectAPIName);
                        connectObjectRTList.addAll(co.objectRecordTypes);
                        system.debug('connectObjectRTList ==> ' + connectObjectRTList);
                        connectObjectRTList.add(createConnectObjectRTList(raParentWrapper, connectObjectData)); 
                    }
                }
                
                if(!isTheSameConnectorObject){
                    connectObjectRTList.add(createConnectObjectRTList(raParentWrapper, connectObjectData)); 
                }
            }
            else{
                system.debug('else2 ==> ' + raParentWrapper.objectAPIName);
                connectObjectRTList.add(createConnectObjectRTList(raParentWrapper, connectObjectData));  
            }
            
            // need to remove it later
            for(roCalendarWrapper.recordTypesWrapper rtw: connectObjectRTList){
                connectObjectDataList.addAll(rtw.objectData);
            }
            
            currentConnectorObject.objectRecordTypes = connectObjectRTList;
            currentConnectorObject.objectData = connectObjectDataList; // need to remove it later
            return currentConnectorObject;
        }
        catch(exception ex){
            //log exception in log object 
            system.debug('ERROR creating wrapper '+ex.getMessage()+' at '+ex.getStackTraceString());
            return null;
        }
    }
    
    public static roCalendarWrapper.recordTypesWrapper createConnectObjectRTList(roCalendarWrapper.resourceAllocationParentWrapper raParentWrapper, List<Sobject> connectObjectData){
        List<roCalendarWrapper.connectorObjectData> connectObjectDataList = new List<roCalendarWrapper.connectorObjectData>();
        List<roCalendarWrapper.recordTypesWrapper> connectObjectRTList = new List<roCalendarWrapper.recordTypesWrapper>();
        
        system.debug('raParentWrapper api name ==>'+ raParentWrapper.objectAPIName);
        roCalendarWrapper.recordTypesWrapper rtWrapper = new roCalendarWrapper.recordTypesWrapper();
        rtWrapper.recordTypeId = raParentWrapper.recordTypeId;
        rtWrapper.recordTypeName = raParentWrapper.recordTypeName;
        rtWrapper.recordTypeDeveloperName = raParentWrapper.recordTypeDeveloperName;
        
        for(Sobject rec :connectObjectData){
            Id recordId = (Id) rec.get('Id');
            DescribeSObjectResult sobjeResult = recordId.getsobjecttype().getDescribe();
            string objectAPIName = sobjeResult.getName();
            string objectLabel = sobjeResult.getLabel();
            
            roCalendarWrapper.connectorObjectData currentRecord = new roCalendarWrapper.connectorObjectData();
            currentRecord.recordId = (string) rec.get('Id');
            currentRecord.recordName = (string) rec.get('Name');
            
            if(!String.isBlank(raParentWrapper.startDateTimeFielAPI) &&  !String.isBlank(raParentWrapper.endDateTimeFielAPI) && 
               rec.get(raParentWrapper.startDateTimeFielAPI) != null && rec.get(raParentWrapper.endDateTimeFielAPI) != null){
                   currentRecord.startDateTime = (string) string.valueOf(rec.get(raParentWrapper.startDateTimeFielAPI));
                   currentRecord.endDateTime = (string) string.valueOf(rec.get(raParentWrapper.endDateTimeFielAPI));
               }
            
            /*if(!String.isBlank(raParentWrapper.descriptionFieldAPI)){
                currentRecord.description = (string) rec.get(raParentWrapper.descriptionFieldAPI);
            }*/
            
            List<roCalendarWrapper.columnWrapper> columnDataList = new List<roCalendarWrapper.columnWrapper>();
            for(roCalendarWrapper.columnWrapper columnMetadata :raParentWrapper.columns){
                roCalendarWrapper.columnWrapper columnData = new roCalendarWrapper.columnWrapper();
                columnData.fieldLabel = columnMetadata.fieldLabel;
                columnData.fieldApiName = columnMetadata.fieldApiName;
                columnData.fieldValue = (string) rec.get(columnMetadata.fieldApiName);
                columnDataList.add(columnData);
            }
            currentRecord.columns = columnDataList;
            connectObjectDataList.add(currentRecord);
        }
        
        rtWrapper.objectData = connectObjectDataList;
        rtWrapper.columnMetadata = raParentWrapper.columns;
        connectObjectRTList.add(rtWrapper);
        
        return rtWrapper;
    }
    
    @AuraEnabled
    public static string saveAllocationRecord(string recId, string resourceId){
        List<Resource__c> r = [select id, User__c from Resource__c where User__c=:resourceId];
        if(r.size()>0){
            Resource_Allocation__c resourceAllocation = new Resource_Allocation__c();
            resourceAllocation.Id = recId;
            resourceAllocation.Resource__c = r[0].Id;
            update resourceAllocation;
            return string.valueOf(resourceAllocation.Id);
        }
        return null;
    }
    
}