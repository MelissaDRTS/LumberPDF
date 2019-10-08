public class RTS_Portal_AllTasks {
    
    public static Id getUserId() {
        return UserInfo.getUserId();
    }

    @AuraEnabled
    public static List<Task> getAllTasks() {
        Id userId = getUserId();
        List<Task> allTasks = [SELECT Id, Subject FROM Task WHERE OwnerId = :userId AND Status = 'Open'];
        System.debug(allTasks);
        return allTasks;
    }
}