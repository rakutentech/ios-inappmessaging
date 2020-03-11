/// Helper class with methods to check if a campaign is ready to be displayed.
internal struct TriggerAttributesValidator {

    /// Check if the trigger has been satisfied or not. A trigger is
    /// satisfied if all of its attributes are satisfied.
    /// - Parameter trigger: The trigger to reconcile.
    /// - Parameter event: The event to match the trigger against.
    /// - Returns: `true` if the trigger and event matches.
    static func isTriggerSatisfied(_ trigger: Trigger, _ event: Event) -> Bool {

        // Iterate through all the trigger attributes.
        for triggerAttribute in trigger.attributes {

            // Return false if there isnt a matching trigger name between the trigger and event.
            guard let eventAttribute = event.getAttributeMap()?[triggerAttribute.name] else {
                return false
            }

            // Since there is a matching name between the trigger and event, see if the attributes are satisfied.
            if !isAttributeSatisfied(triggerAttribute, eventAttribute) {
                // If the attribute is not satisfied, then the trigger cannot be satisfied.
                return false
            }

        }

        // Return true since all the attributes are matched.
        return true
    }

    /// Check if a trigger attribute and event attribute matches.
    ///
    /// It is considered a match with several conditions:
    /// 1) Event name for both matches.
    /// 2) Event type for both matches.
    /// 3) Both values satisfies the operator.
    /// - Parameter triggerAttribute: Attribute of the trigger.
    /// - Parameter eventAttribute: Attribute of the event.
    /// - Returns: A flag indicating whether or not the attributes match.
    private static func isAttributeSatisfied(_ triggerAttribute: TriggerAttribute, _ eventAttribute: CustomAttribute) -> Bool {

        // Make sure the attribute name and event attribute name is the same.
        if triggerAttribute.name != eventAttribute.name {
            return false
        }

        // Make sure the value type between the attribute value and event value is the same.
        if triggerAttribute.type != eventAttribute.type {
            return false
        }

        return isValueReconciled(
            withValueType: triggerAttribute.type,
            withOperator: triggerAttribute.operator,
            withTriggerAttributeValue: triggerAttribute.value,
            withEventAttributeValue: eventAttribute.value
        )
    }

    /// Checks the attributes's value to see if they fit the operator.
    /// It will cast the attribute's value to its proper type and
    /// compare the values using the operator.
    /// - Parameter valueType: Value type of the attributes.
    /// - Parameter operatorType: The comparison operator used.
    /// - Parameter triggerValue: Value of the trigger attribute that will be casted to the eventType.
    /// - Parameter eventValue: Value of the event that will be casted to the eventType.
    /// - Returns: A flag indicating whether or not the values of both attributes are satisfied.
    private static func isValueReconciled(
        withValueType valueType: AttributeType,
        withOperator operatorType: AttributeOperator,
        withTriggerAttributeValue triggerValue: String,
        withEventAttributeValue eventValue: Any) -> Bool {

        switch valueType {

        case .invalid:
            return false

        case .string:
            guard let stringEventValue = eventValue as? String else {
                CommonUtility.debugPrint("InAppMessaging: Error converting value.")
                return false
            }

            return MatchingUtility.compareValues(
                triggerAttributeValue: triggerValue,
                eventAttributeValue: stringEventValue,
                operatorType: operatorType
            )

        case .integer:
            guard let intEventValue = eventValue as? Int,
                let intTriggerValue = Int(triggerValue)
                else {
                    CommonUtility.debugPrint("InAppMessaging: Error converting value.")
                    return false
            }

            return MatchingUtility.compareValues(
                triggerAttributeValue: intTriggerValue,
                eventAttributeValue: intEventValue,
                operatorType: operatorType
            )
        case .double:
            guard let doubleEventValue = eventValue as? Double,
                let doubleTriggerValue = Double(triggerValue)
                else {
                    CommonUtility.debugPrint("InAppMessaging: Error converting value.")
                    return false
            }

            return MatchingUtility.compareValues(
                triggerAttributeValue: doubleTriggerValue,
                eventAttributeValue: doubleEventValue,
                operatorType: operatorType
            )

        case .boolean:
            guard let boolEventValue = eventValue as? Bool,
                let boolTriggerValue = Bool(triggerValue.lowercased())
                else {
                    CommonUtility.debugPrint("InAppMessaging: Error converting value.")
                    return false
            }

            return MatchingUtility.compareValues(
                triggerAttributeValue: boolTriggerValue,
                eventAttributeValue: boolEventValue,
                operatorType: operatorType
            )

        case .timeInMilli:
            guard let timeEventValue = eventValue as? Int,
                let timeTriggerValue = Int(triggerValue)
                else {
                    CommonUtility.debugPrint("InAppMessaging: Error converting value.")
                    return false
            }

            return MatchingUtility.compareTimeValues(
                triggerAttributeValue: timeTriggerValue,
                eventAttributeValue: timeEventValue,
                operatorType: operatorType
            )
        }
    }
}
