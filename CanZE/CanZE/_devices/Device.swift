//
//  Device.swift
//  CanZE
//
//  Created by Roberto Sonzogni on 23/12/20.
//

import Foundation

class Device {
    let INTERVAL_ASAP = 0 // follows frame rate
    let INTERVAL_ASAPFAST = -1 // truly as fast as possible
    let INTERVAL_ONCE = -2 // one shot

    let TOUGHNESS_HARD = 0 // hardest reset possible (ie atz)
    let TOUGHNESS_MEDIUM = 1 // medium reset (i.e. atws)
    let TOUGHNESS_SOFT = 2 // softest reset (i.e atd for ELM)
    let TOUGHNESS_NONE = 100 // just clear error status

    let minIntervalMultiplicator = 1.3
    let maxIntervalMultiplicator = 2.5
    var intervalMultiplicator = 1.3 // initial value as minIntervalMultiplicator
    var deviceIsInitialized = false // if true initConnection will only start a new pollerthread

    /* ----------------------------------------------------------------
     * Attributes
     \ -------------------------------------------------------------- */

    /**
     * A device will "monitor" or "request" a given number of fields from
     * the connected CAN-device, so this is the list of all fields that
     * have to be read and updated.
     */
    var fields: [Field] = []
    /**
     * Some fields will be custom, activity based
     */
    var activityFieldsScheduled: [Field] = []
    var activityFieldsAsFastAsPossible: [Field] = []
    /**
     * Some other fields will have to be queried anyway,
     * such as e.g. the speed --> safe mode driving
     */
    var applicationFields: [Field] = []

    /**
     * The index of the actual field to query.
     * Loops over ther "fields" array
     */
    // protected int fieldIndex = 0

    var activityFieldIndex = 0

    var pollerActive = false
    // Thread pollerThread

    /**
     * lastInitProblem should be filled with a descriptive problem description by the initDevice implementation. In normal operation we don't care
     * because a device either initializes or not, but for testing a new device this can be very helpful.
     */
    var lastInitProblem = ""
    
    var type = ""
}
