/// Helper class with methods to check if a campaign is ready to be displayed.
internal struct TriggerAttributesValidator {

    /// Check if the trigger has been satisfied or not. A trigger is
    /// satisfied if all of its attributes are satisfied.
    /// - Parameter trigger: The trigger to reconcile.
    /// - Parameter event: The event to match the trigger against.
    /// - Returns: `true` if the trigger and event matches.
    static func isTriggerSatisfied(_ trigger: Trigger, _ event: Event) -> Bool {

        return trigger.attributes.allSatisfy { triggerAttribute -> Bool in
            guard let eventAttribute = event.getAttributeMap()?[triggerAttribute.name] else {
                return false
            }

            return isAttributeSatisfied(triggerAttribute, eventAttribute)
        }
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

        guard triggerAttribute.name == eventAttribute.name,
            triggerAttribute.type == eventAttribute.type else {
            return false
        }

        return isValueReconciled(
            valueType: triggerAttribute.type,
            operator: triggerAttribute.operatorType,
            triggerAttributeValue: triggerAttribute.value,
            eventAttributeValue: eventAttribute.value
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
        valueType: AttributeType,
        operator operatorType: AttributeOperator,
        triggerAttributeValue triggerValue: String,
        eventAttributeValue eventValue: Any) -> Bool {

        switch valueType {

        case .invalid:
            IAMLogger.debug("Error - invalid attribute value")
            return false

        case .string:
            guard let stringEventValue = eventValue as? String else {
                break
            }

            return MatchingUtility.compareValues(
                triggerAttributeValue: triggerValue,
                eventAttributeValue: stringEventValue,
                operatorType: operatorType
            )

        case .integer:
            guard let intEventValue = eventValue as? Int,
                let intTriggerValue = Int(triggerValue)
                else { break }

            return MatchingUtility.compareValues(
                triggerAttributeValue: intTriggerValue,
                eventAttributeValue: intEventValue,
                operatorType: operatorType
            )
        case .double:
            guard let doubleEventValue = eventValue as? Double,
                let doubleTriggerValue = Double(triggerValue)
                else { break }

            return MatchingUtility.compareValues(
                triggerAttributeValue: doubleTriggerValue,
                eventAttributeValue: doubleEventValue,
                operatorType: operatorType
            )

        case .boolean:
            guard let boolEventValue = eventValue as? Bool,
                let boolTriggerValue = Bool(triggerValue.lowercased())
                else { break }

            return MatchingUtility.compareValues(
                triggerAttributeValue: boolTriggerValue,
                eventAttributeValue: boolEventValue,
                operatorType: operatorType
            )

        case .timeInMilliseconds:
            guard let timeEventValue = eventValue as? Int,
                let timeTriggerValue = Int(triggerValue)
                else { break }

            return MatchingUtility.compareTimeValues(
                triggerAttributeValue: timeTriggerValue,
                eventAttributeValue: timeEventValue,
                operatorType: operatorType
            )
        }

        IAMLogger.debug("Error converting values")
        return false
    }
}
