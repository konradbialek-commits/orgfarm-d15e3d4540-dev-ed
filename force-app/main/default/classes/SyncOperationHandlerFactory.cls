public class SyncOperationHandlerFactory {
    public static SyncOperationHandler getHandler(String operation) {
        if (String.isBlank(operation)) {
            throw new IllegalArgumentException('Operation cannot be blank');
        }
        
        String className = operation.toLowerCase().capitalize() + 'OperationHandler';
        Type handlerType = Type.forName(className);
        
        if (handlerType != null) {
            return (SyncOperationHandler) handlerType.newInstance();
        }
        
        throw new IllegalArgumentException('No handler found for operation: ' + operation);
    }
}