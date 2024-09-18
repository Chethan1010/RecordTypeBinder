public class RecordTypeChangeScheduler implements Schedulable {
    public void execute(SchedulableContext sc) {
	/*List<RecordType> newRecordTypes = [SELECT Id, Name, DeveloperName,SObjectType FROM RecordType];
        List<RecordTypeCache__c> cachedRecordTypes = [SELECT Id, Name, DeveloperName__c FROM RecordTypeCache__c];
        System.debug('New Record Types: ' + newRecordTypes);
        System.debug('Cached Record Types: ' + cachedRecordTypes);*/

        // Call the utility method to synchronize the cache
        RecordTypeCacheUtility.synchronizeCache();
}
}
