export const Util = {
    Strategy: {
        LOWEST: 'Lowest',
        HIGHEST: 'Highest',
        CUMULATIVE: 'Cumulative'
    },
    Discount: {
        CAT_ONETIME: 'One Time Only',
        CAT_RECURRING: 'Recurring',
        CAT_CONDITIONAL: 'Conditional',
        
        COND_MIN_ORDER: 'Minimum Order Value',
        COND_TWO_FOR_ONE: 'Two For One',
        COND_VOLUME: 'Volume Tier',
        
        TYPE_PERCENT: 'Percent',
        TYPE_FIXED: 'Fixed Amount',
        
        REC_NONE: 'None',
        REC_DAILY: 'Daily',
        REC_MONDAY: 'Every Monday',
        REC_FRIDAY: 'Every Friday',
        REC_FIRST_MONTH: 'First Day of Month',
        REC_FIRST_QUARTER: 'First Day of Quarter',
        REC_YEARLY_CUSTOM: 'Yearly Custom Date',
        
        TARGET_ALL: 'All Products',
        TARGET_FAMILIES: 'Specific Families',
        TARGET_PRODUCTS: 'Specific Products'
    },
    Schema: {
        OBJ_DISCOUNT: 'Discount__c',
        FLD_NAME: 'Name',
        FLD_ACTIVE: 'Active__c',
        FLD_TARGET: 'Target_Type__c',
        FLD_TYPE: 'Discount_Type__c',
        FLD_VALUE: 'Value__c',
        FLD_RECURRENCE: 'Recurrence__c',
        FLD_FAMILY: 'Family'
    },
    Action: {
        EDIT: 'edit'
    }
};