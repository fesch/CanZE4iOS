//
//  Fields.swift
//  CanZE
//
//  Created by Roberto Sonzogni on 22/12/20.
//

import Foundation

struct Fields {
    let FIELD_SID = 0 // to be stated in HEX, no leading 0x
    let FIELD_ID = 1 // to be stated in HEX, no leading 0x
    let FIELD_FROM = 2 // decimal
    let FIELD_TO = 3 // decimal
    let FIELD_RESOLUTION = 4 // double
    let FIELD_OFFSET = 5 // double
    let FIELD_DECIMALS = 6 // decimal
    let FIELD_UNIT = 7
    // let FIELD_REQUEST_ID = 8 // to be stated in HEX, no leading 0x
    let FIELD_RESPONSE_ID = 9 // to be stated in HEX, no leading 0x
    let FIELD_OPTIONS = 10 // to be stated in HEX, no leading 0x
    let FIELD_NAME = 11 // can be displayed/saved. Now only used for Diag ISO-TP
    let FIELD_LIST = 12 // same

    var fields: [Field] = []

    var fieldsBySid: [String: Field] = [:]

//    var static Fields instance = null
    var runningUsage: Double = 0
    var realRangeReference = Double.nan
    var realRangeReference2 = Double.nan
    var start = Date().timeIntervalSince1970 // long Calendar.getInstance().getTimeInMillis()

//      var LocationManager locationManager
//      var LocationListener locationListener

    // var int car = CAR_ANY

    static var getInstance = Fields()

    mutating func load(assetName: String) {
        fields = []
        fieldsBySid = [:]

        if assetName == "" {
            fillFromAsset(assetName: getDefaultAssetName())
            addVirtualFields()
//        } else if assetName.starts(with: "/") {
//            fillFromFile(assetName)
        } else {
            fillFromAsset(assetName: assetName)
            //// if (assetName.startsWith("VFC")) {
            ////    addVirtualFields();
            //// }
        }
    }

    func getDefaultAssetName() -> String {
        var p = "_assets/" + Utils.getAssetPrefix()
        if Utils.isZOE(), AppSettings.shared.useIsoTpFields {
            p += "_FieldsAlt.csv"
        } else {
            p += "_Fields.csv"
        }
        return p
    }

    mutating func fillFromAsset(assetName: String) {
        let p = assetName
        let path = Bundle.main.path(forResource: p, ofType: nil)
        if path != nil {
            do {
                let completo = try String(contentsOfFile: path!, encoding: .utf8)
                let righe = completo.components(separatedBy: "\n")
                // print(righe.count)
                for riga in righe {
                    fillOneLine(line_: riga)
                }
                print("loaded ecus: \(Ecus.getInstance.ecus.count)")
                print("loaded frames: \(Frames.getInstance.frames.count)")
                print("loaded fields: \(fields.count)")
            } catch {
                print(error.localizedDescription)
            }
        } else {
            print("\(p) not found")
        }
    }

    mutating func fillOneLine(line_: String) {
        var line = line_
        if line.contains("#") {
            line = String(line[..<line.firstIndex(of: "#")!])
        }
        let tokens = line.components(separatedBy: ",")
        if tokens.count > FIELD_OPTIONS {
            let frameId = Int(trim(s: tokens[FIELD_ID]), radix: 16)
            var frame = Frames.getInstance.getById(id: frameId!)
            if frame == nil {
                print("(frame does not exist: \(tokens[FIELD_ID]))")
            } else {
                if frameId! < 0x800 || frameId! > 0x8ff {
                    let options = Int(trim(s: tokens[FIELD_OPTIONS]), radix: 16)
                    // ensure this field matches the selected car
                    if (options! & AppSettings.shared.car) != 0, !trim(s: tokens[FIELD_RESPONSE_ID]).starts(with: "7") || trim(s: tokens[FIELD_RESPONSE_ID]).lowercased().starts(with: "7e") {
                        // Create a new field object and fill his  data
                        // MainActivity.debug(tokens[FIELD_SID] + " " + tokens[FIELD_ID] + "." + tokens[FIELD_FROM] + "." + tokens[FIELD_RESPONSE_ID])

                        // 658.33,18DAF1DB,24,39,.01,0,2,%,229003,629003,ff,Battery SOH(Zxx_sohe_avg)

                        let field = Field(
                            sid: trim(s: tokens[FIELD_SID]),
                            frame: frame,
                            from: Int(trim(s: tokens[FIELD_FROM])),
                            to: Int(trim(s: tokens[FIELD_TO])),
                            resolution: Double(trim(s: tokens[FIELD_RESOLUTION])),
                            offset: Int64(trim(s: tokens[FIELD_OFFSET])),
                            decimals: Int(trim(s: tokens[FIELD_DECIMALS])),
                            unit: trim(s: tokens[FIELD_UNIT]),

                            responseId: trim(s: tokens[FIELD_RESPONSE_ID]),
                            options: options,
                            name: (tokens.count > FIELD_NAME) ? tokens[FIELD_NAME] : "",
                            list: (tokens.count > FIELD_LIST) ? tokens[FIELD_LIST] : ""
                        )

                        // we are maintaining a list of all fields in a frame so we can very
                        // quickly update all fields when a message (=frame data) comes in
                        // note that for free frames a frame is identified by it's ID and itś definition
                        // is entirely given
                        // for an ISOTP frame (diagnostics) frame, the frame is just a skeleton and
                        // the definition is entirely dependant on the responseID. Therefor, when an
                        // ISOTP field is defined, new frames are created dynamically
                        if field.isIsoTp() {
                            var subFrame = Frames.getInstance.getById(id: frameId!, responseId: field.responseId)
                            if subFrame == nil {
                                subFrame = Frame(fromId: frame?.fromId, responseId: field.responseId, sendingEcu: frame?.sendingEcu, fields: [], queriedFields: [], interval: frame?.interval, lastRequest: 0) // TODO: manca containingFrame
                                Frames.getInstance.frames.append(subFrame!)
                            }
                            subFrame?.fields.append(field)
                            field.frame = subFrame
                        } else {
                            frame!.fields.append(field)
                        }
                        // add the field to the list of available fields
                        fields.append(field)

//                        if field.sid == "42e.0" {
//                            print(field.sid)
//                        }
                        fieldsBySid[field.sid] = field
                    }

                } else {
                    addVirtualField(id: trim(s: tokens[FIELD_RESPONSE_ID]))
                }
            }
        }
        // TODO: registerApplicationFields()
    }

    mutating func addVirtualFields() {
        addVirtualFieldUsage()
        addVirtualFieldUsageLpf()
        addVirtualFieldFrictionTorque()
        // addVirtualFieldFrictionPower()
        addVirtualFieldElecBrakeTorque()
        addVirtualFieldTotalPositiveTorque()
        addVirtualFieldTotalNegativeTorque()
        addVirtualFieldDcPowerIn()
        addVirtualFieldDcPowerOut()
        addVirtualFieldHeaterSetpoint()
        addVirtualFieldRealRange()
        addVirtualFieldRealDelta()
        addVirtualFieldRealDeltaNoReset()
        addVirtualFieldPilotAmp()
    }

    mutating func addVirtualField(id: String) {
        switch id {
            case "6100":
                addVirtualFieldUsage()
            case "6104":
                addVirtualFieldUsageLpf()
            case "6101":
                addVirtualFieldFrictionTorque()
            case "610a":
                addVirtualFieldElecBrakeTorque()
            case "610b":
                addVirtualFieldTotalPositiveTorque()
            case "610c":
                addVirtualFieldTotalNegativeTorque()
            case "6103":
                addVirtualFieldDcPowerIn()
            case "6109":
                addVirtualFieldDcPowerOut()
            case "6105":
                addVirtualFieldHeaterSetpoint()
            case "6106":
                addVirtualFieldRealRange()
            case "6107":
                addVirtualFieldRealDelta()
            case "6108":
                addVirtualFieldRealDeltaNoReset()
            case "610d":
                addVirtualFieldPilotAmp()
            case "610e":
                addVirtualFieldGps()
            default:
                print("error loading virtual field")
        }
    }

    struct VirtualFieldAction {
        // TODO: func updateValue(HashMap<String,Field> dependantFields)
    }

    mutating func addVirtualFieldCommon(virtualId: String, decimals: Int?, unit: String, dependantSids: String) { // , virtualFieldAction: VirtualFieldAction?) {
        // create a list of field this new virtual field will depend on
        var dependantFields: [String: Field] = [:]
        var allOk = true

        for sid in dependantSids.components(separatedBy: ";") {
            let field = getBySID(sid: sid)
            if field != nil {
                if field?.responseId != "999999" {
                    dependantFields[sid] = field
                } else { // else not ok, but no error toast display. This is a temporary hack to avoid toast overload while fixing _FieldsPh2
                    allOk = false
                }
            } else {
                allOk = false
                // TODO: MainActivity.toast(MainActivity.TOAST_NONE, String.format(Locale.getDefault(), MainActivity.getStringSingle(R.string.format_NoSid), "Fields", sid))
                print("field \(sid) not found")
            }
        }
        if allOk {
            let virtualField = VirtualField(responseId: virtualId, dependantFields: dependantFields, decimals: decimals ?? 0, unit: unit) // virtualFieldAction)
            // a virtualfield is always ISO-TP, so we need to create a subframe for it
            let frame = Frames.getInstance.getById(id: 0x800)
            if frame == nil {
                print("frame does not exist: 0x800")
                return
            }
            if virtualField.responseId != nil {
                var subFrame = Frames.getInstance.getById(id: 0x800, responseId: virtualField.responseId)
                if subFrame == nil {
                    subFrame = Frame(fromId: frame?.fromId, responseId: virtualField.responseId, sendingEcu: frame?.sendingEcu, fields: [], queriedFields: [], interval: frame?.interval, lastRequest: 0)
                    Frames.getInstance.frames.append(subFrame!)
                }
                subFrame?.fields.append(virtualField)
                virtualField.frame = subFrame
                // add it to the list of fields
                fields.append(virtualField)
                fieldsBySid[virtualField.sid] = virtualField
            } else {
                var subFrame = Frame(fromId: frame?.fromId, responseId: virtualField.responseId, sendingEcu: frame?.sendingEcu, fields: [], queriedFields: [], interval: frame?.interval, lastRequest: 0)
                Frames.getInstance.frames.append(subFrame)
                subFrame.fields.append(virtualField)
                virtualField.frame = subFrame
                // add it to the list of fields
                fields.append(virtualField)
                fieldsBySid[virtualField.sid] = virtualField
            }
        }
    }

    mutating func addVirtualFieldUsage() {
        // It would be easier use SID_Consumption = "1fd.48" (dash kWh) instead of V*A
        addVirtualFieldCommon(virtualId: "6100", decimals: nil, unit: "kWh/100km", dependantSids: Sid.TractionBatteryVoltage + ";" + Sid.TractionBatteryCurrent + ";" + Sid.RealSpeed) /* , new VirtualFieldAction() {
             @Override
             public double updateValue(HashMap<String, Field> dependantFields) {
                 // get real speed
                 Field privateField;
                 if ((privateField = dependantFields.get(Sid.RealSpeed)) == null) return Double.NaN;
                 double realSpeed = privateField.getValue();
                 if (realSpeed < 0 || realSpeed > 150) return Double.NaN;
                 if (realSpeed < 5) return 0;
                 // get voltage
                 if ((privateField = dependantFields.get(Sid.TractionBatteryVoltage)) == null) return Double.NaN;
                 double dcVolt = privateField.getValue();
                 // get current
                 if ((privateField = dependantFields.get(Sid.TractionBatteryCurrent)) == null) return Double.NaN;
                 double dcCur = privateField.getValue();
                 if (dcVolt < 300 || dcVolt > 450 || dcCur < -200 || dcCur > 100) return Double.NaN;
                 // power in kW
                 double dcPwr = dcVolt * dcCur / 1000.0;
                 double usage = -(Math.round(1000.0 * dcPwr / realSpeed) / 10.0);
                 if (usage < -150) return -150;
                 else if (usage > 150) return 150;
                 else return usage;
             }
         }); */
    }

    mutating func addVirtualFieldFrictionTorque() {
        if AppSettings.shared.useIsoTpFields || Utils.isPh2() {
            addVirtualFieldCommon(virtualId: "6101", decimals: nil, unit: "Nm", dependantSids: Sid.HydraulicTorqueRequest) /* , new VirtualFieldAction() {
                 @Override
                 public double updateValue(HashMap<String, Field> dependantFields) {
                     Field privateField;
                     if ((privateField = dependantFields.get(Sid.HydraulicTorqueRequest)) == null)
                         return Double.NaN;
                     return -privateField.getValue();
                 }
             }); */

        } else {
            addVirtualFieldCommon(virtualId: "6101", decimals: nil, unit: "Nm", dependantSids: Sid.DriverBrakeWheel_Torque_Request + ";" + Sid.ElecBrakeWheelsTorqueApplied + ";" + Sid.Coasting_Torque) /* , new VirtualFieldAction() {
                 @Override
                 public double updateValue(HashMap<String, Field> dependantFields) {
                     Field privateField;
                     if ((privateField = dependantFields.get(Sid.DriverBrakeWheel_Torque_Request)) == null)
                         return Double.NaN;
                     double requestedTorque = privateField.getValue();
                     if ((privateField = dependantFields.get(Sid.ElecBrakeWheelsTorqueApplied)) == null)
                         return Double.NaN;
                     double electricTorque = privateField.getValue();
                     if ((privateField = dependantFields.get(Sid.Coasting_Torque)) == null)
                         return Double.NaN;
                     double coastingTorque = privateField.getValue();

                     return requestedTorque - electricTorque - coastingTorque;
                 }
             }); */
        }
    }

    mutating func addVirtualFieldElecBrakeTorque() {
        if AppSettings.shared.useIsoTpFields || Utils.isPh2() {
            addVirtualFieldCommon(virtualId: "610a", decimals: nil, unit: "Nm", dependantSids: Sid.PEBTorque) /* , new VirtualFieldAction() {
                 @Override
                 public double updateValue(HashMap<String, Field> dependantFields) {
                     Field privateField;
                     if ((privateField = dependantFields.get(Sid.PEBTorque)) == null)
                         return Double.NaN;
                     double electricTorque = privateField.getValue() * MainActivity.reduction;
                     return electricTorque <= 0 ? -electricTorque : 0;
                 }
             }); */

        } else {
            addVirtualFieldCommon(virtualId: "610a", decimals: nil, unit: "Nm", dependantSids: Sid.ElecBrakeWheelsTorqueApplied + ";" + Sid.Coasting_Torque) /* , new VirtualFieldAction() {
                     @Override
                     public double updateValue(HashMap<String, Field> dependantFields) {
                         Field privateField;
                         if ((privateField = dependantFields.get(Sid.ElecBrakeWheelsTorqueApplied)) == null)
                             return Double.NaN;
                         double electricTorque = privateField.getValue();
                         if ((privateField = dependantFields.get(Sid.Coasting_Torque)) == null)
                             return Double.NaN;
                         return electricTorque + (privateField.getValue() * MainActivity.reduction);
                     }
             }); */
        }
    }

    mutating func addVirtualFieldTotalPositiveTorque() {
        if AppSettings.shared.useIsoTpFields || Utils.isPh2() {
            addVirtualFieldCommon(virtualId: "610b", decimals: nil, unit: "Nm", dependantSids: Sid.PEBTorque) /* , new VirtualFieldAction() {
                 @Override
                 public double updateValue(HashMap<String, Field> dependantFields) {
                     Field privateField;
                     if ((privateField = dependantFields.get(Sid.PEBTorque)) == null)
                         return Double.NaN;
                     double pebTorque = privateField.getValue();
                     return pebTorque >= 0 ? pebTorque * MainActivity.reduction : 0;
                 }
             }); */

        } else {
            addVirtualFieldCommon(virtualId: "610b", decimals: nil, unit: "Nm", dependantSids: Sid.MeanEffectiveTorque) /* , new VirtualFieldAction() {
                     @Override
                     public double updateValue(HashMap<String, Field> dependantFields) {
                         Field privateField;
                         if ((privateField = dependantFields.get(Sid.MeanEffectiveTorque)) == null)
                             return Double.NaN;
                         return privateField.getValue() * MainActivity.reduction;
                     }
             }); */
        }
    }

    mutating func addVirtualFieldTotalNegativeTorque() {
        if AppSettings.shared.useIsoTpFields || Utils.isPh2() {
            addVirtualFieldCommon(virtualId: "610c", decimals: nil, unit: "Nm", dependantSids: Sid.PEBTorque + ";" + Sid.HydraulicTorqueRequest) /* , new VirtualFieldAction() {
                 @Override
                 public double updateValue(HashMap<String, Field> dependantFields) {
                     Field privateField;
                     if ((privateField = dependantFields.get(Sid.HydraulicTorqueRequest)) == null)
                         return Double.NaN;
                     double hydraulicTorqueRequest = privateField.getValue();
                     if ((privateField = dependantFields.get(Sid.PEBTorque)) == null)
                         return Double.NaN;
                     double pebTorque = privateField.getValue();
                     return pebTorque <= 0 ? -hydraulicTorqueRequest - pebTorque * MainActivity.reduction : -hydraulicTorqueRequest;
                 }
             }); */

        } else {
            addVirtualFieldCommon(virtualId: "610c", decimals: nil, unit: "Nm", dependantSids: Sid.DriverBrakeWheel_Torque_Request) /* , new VirtualFieldAction() {
                 @Override
                 public double updateValue(HashMap<String, Field> dependantFields) {
                     Field privateField;
                     if ((privateField = dependantFields.get(Sid.DriverBrakeWheel_Torque_Request)) == null)
                         return Double.NaN;
                     return privateField.getValue();
                 }
             }); */
        }
    }

    /*
     func  addVirtualFieldFrictionPower() {
         final String SID_DriverBrakeWheel_Torque_Request = "130.44"; //UBP braking wheel torque the driver wants
         final String SID_ElecBrakeWheelsTorqueApplied = "1f8.28"; //10ms
         final String SID_ElecEngineRPM = "1f8.40"; //10ms

         addVirtualFieldCommon("6102", "kW", SID_DriverBrakeWheel_Torque_Request + ";" + SID_ElecBrakeWheelsTorqueApplied + ";" + SID_ElecEngineRPM, new VirtualFieldAction() {
             @Override
             public double updateValue(HashMap<String, Field> dependantFields) {
                 Field privateField;
                 if ((privateField = dependantFields.get(SID_DriverBrakeWheel_Torque_Request)) == null) return Double.NaN;
                 double torque = privateField.getValue();
                 if ((privateField = dependantFields.get(SID_ElecBrakeWheelsTorqueApplied)) == null) return Double.NaN;
                 torque -= privateField.getValue();
                 if ((privateField = dependantFields.get(SID_ElecEngineRPM)) == null) return Double.NaN;
                 return (torque * privateField.getValue() / MainActivity.reduction);
                 //return (dependantFields.get(SID_DriverBrakeWheel_Torque_Request).getValue() - dependantFields.get(SID_ElecBrakeWheelsTorqueApplied).getValue()) * dependantFields.get(SID_ElecEngineRPM).getValue() / MainActivity.reduction;
             }
         });
     }
     */
    mutating func addVirtualFieldDcPowerIn() {
        // positive = charging, negative = discharging. Unusable for consumption graphs
        addVirtualFieldCommon(virtualId: "6103", decimals: nil, unit: "kW", dependantSids: Sid.TractionBatteryVoltage + ";" + Sid.TractionBatteryCurrent) /* , new VirtualFieldAction() {
             @Override
             public double updateValue(HashMap<String, Field> dependantFields) {
                 Field privateField;
                 if ((privateField = dependantFields.get(Sid.TractionBatteryVoltage)) == null) return Double.NaN;
                 double voltage = privateField.getValue();
                 if ((privateField = dependantFields.get(Sid.TractionBatteryCurrent)) == null) return Double.NaN;
                 return (voltage * privateField.getValue() / 1000.0);
                 //return dependantFields.get(SID_TractionBatteryVoltage).getValue() * dependantFields.get(SID_TractionBatteryCurrent).getValue() / 1000;
             }
         });*/
    }

    mutating func addVirtualFieldDcPowerOut() {
        // positive = discharging, negative = charging. Unusable for harging graphs
        addVirtualFieldCommon(virtualId: "6109", decimals: nil, unit: "kW", dependantSids: Sid.TractionBatteryVoltage + ";" + Sid.TractionBatteryCurrent) /* , new VirtualFieldAction() {
             @Override
             public double updateValue(HashMap<String, Field> dependantFields) {
                 Field privateField;
                 if ((privateField = dependantFields.get(Sid.TractionBatteryVoltage)) == null) return Double.NaN;
                 double voltage = privateField.getValue();
                 if ((privateField = dependantFields.get(Sid.TractionBatteryCurrent)) == null) return Double.NaN;
                 return (voltage * privateField.getValue() / -1000.0);
             }
         }); */
    }

    mutating func addVirtualFieldUsageLpf() {
        // It would be easier use SID_Consumption = "1fd.48" (dash kWh) instead of V*A
        // need to use real timer. Now the averaging is dependant on dongle speed
        let SID_VirtualUsage = "800.6100.24"

        addVirtualFieldCommon(virtualId: "6104", decimals: nil, unit: "kWh/100km", dependantSids: SID_VirtualUsage) // , new VirtualFieldAction() {
        /* @Override
             public double updateValue(HashMap<String, Field> dependantFields) {
                 Field privateField;
                 if ((privateField = dependantFields.get(SID_VirtualUsage)) == null) return Double.NaN;
                 double value = privateField.getValue();
                 if (!Double.isNaN(value)) {
                     long now = Calendar.getInstance().getTimeInMillis();
                     long since = now - start;
                     if (since > 1000) since = 1000; // use a maximim of 1 second
                     start = now;

                     double factor = since * 0.00005; // 0.05 per second
                     runningUsage = runningUsage * (1 - factor) + value * factor;
                 }
                 return runningUsage;
             }
         })*/
    }

    mutating func addVirtualFieldHeaterSetpoint() {
        if Utils.isPh2() {
            addVirtualFieldCommon(virtualId: "6105", decimals: 1, unit: "°C", dependantSids: Sid.OH_ClimTempDisplay) // , new VirtualFieldAction() {
            /* @Override
                 public double updateValue(HashMap<String, Field> dependantFields) {
                     Field privateField;
                     if ((privateField = dependantFields.get(Sid.OH_ClimTempDisplay)) == null) return Double.NaN;
                     double value = privateField.getValue();
                     if (value == 0) {
                         return Double.NaN;
                     } else if (value == 4) {
                         return -10.0;
                     } else if (value == 5) {
                         return 40.0;
                     }
                     return value;
                 }
             });*/

        } else if AppSettings.shared.useIsoTpFields {
            addVirtualFieldCommon(virtualId: "6105", decimals: nil, unit: "°C", dependantSids: Sid.OH_ClimTempDisplay) // , new VirtualFieldAction() {
            /* @Override
                 public double updateValue(HashMap<String, Field> dependantFields) {
                     Field privateField;
                     if ((privateField = dependantFields.get(Sid.OH_ClimTempDisplay)) == null) return Double.NaN;
                     double value = privateField.getValue() / 2;
                     if (value == 0) {
                         return Double.NaN;
                     } else if (value == 4) {
                         return -10.0;
                     } else if (value == 5) {
                         return 40.0;
                     }
                     return value;
                 }
             });*/

        } else {
            addVirtualFieldCommon(virtualId: "6105", decimals: nil, unit: "°C", dependantSids: Sid.HeaterSetpoint) // , new VirtualFieldAction() {
            /* @Override
                 public double updateValue(HashMap<String, Field> dependantFields) {
                     Field privateField;
                     if ((privateField = dependantFields.get(Sid.HeaterSetpoint)) == null) return Double.NaN;
                     double value = privateField.getValue();
                     if (value == 0) {
                         return Double.NaN;
                     } else if (value == 4) {
                         return -10.0;
                     } else if (value == 5) {
                         return 40.0;
                     }
                     return value;
                 }
             });*/
        }
    }

    mutating func addVirtualFieldRealRange() {
        //   TODO: if realRangeReference == Double.nan {
//            realRangeReference = CanzeDataSource.getInstance().getLast(Sid.RangeEstimate)
//        }

        addVirtualFieldCommon(virtualId: "6106", decimals: nil, unit: "km", dependantSids: Sid.EVC_Odometer + ";" + Sid.RangeEstimate) // , new VirtualFieldAction() {
        /* @Override
             public double updateValue(HashMap<String, Field> dependantFields) {
                 Field privateField;
                 if ((privateField = dependantFields.get(Sid.EVC_Odometer)) == null) return Double.NaN;
                 double odo = privateField.getValue();
                 if ((privateField = dependantFields.get(Sid.RangeEstimate)) == null) return Double.NaN;
                 double gom = privateField.getValue();

                 // timestamp of last inserted dot in MILLISECONDS
                 long lastInsertedTime = CanzeDataSource.getInstance().getLastTime(Sid.RangeEstimate);
                 if (    // timeout of 15 minutes
                         (Calendar.getInstance().getTimeInMillis() - lastInsertedTime > 15 * 60 * 1000)
                                 ||
                                 Double.isNaN(realRangeReference)
                 ) {

                     if (!Double.isNaN(gom) && !Double.isNaN(odo)) {
                         realRangeReference = odo + gom;
                         realRangeReference2 = odo + gom;
                     }
                 }

                 if (Double.isNaN(realRangeReference)) {
                     return Double.NaN;
                 }
                 /*
                 double delta = realRangeReference - odo - gom;
                 if (delta > 12.0 || delta < -12.0) {
                     realRangeReference = odo + gom;
                 } */

                 return realRangeReference - odo;
             }
         });*/
    }

    mutating func addVirtualFieldRealDelta() {
        // get last value for realRange from internal database
        //   TODO: if Double.isNaN(realRangeReference) {
//            realRangeReference = CanzeDataSource.getInstance().getLast(Sid.RangeEstimate)
//        }

        addVirtualFieldCommon(virtualId: "6107", decimals: nil, unit: "km", dependantSids: Sid.EVC_Odometer + ";" + Sid.RangeEstimate) // , new VirtualFieldAction() {
        /* @Override
             public double updateValue(HashMap<String, Field> dependantFields) {
                 Field privateField;
                 if ((privateField = dependantFields.get(Sid.EVC_Odometer)) == null) return Double.NaN;
                 double odo = privateField.getValue();
                 if ((privateField = dependantFields.get(Sid.RangeEstimate)) == null) return Double.NaN;
                 double gom = privateField.getValue();

                 //MainActivity.debug("realRange ODO: "+odo);
                 //MainActivity.debug("realRange GOM: "+gom);

                 // timestamp of last inserted dot in MILLISECONDS
                 long lastInsertedTime = CanzeDataSource.getInstance().getLastTime(Sid.RangeEstimate);
                 if (    // timeout of 15 minutes
                         (Calendar.getInstance().getTimeInMillis() - lastInsertedTime > 15 * 60 * 1000)
                                 ||
                                 Double.isNaN(realRangeReference)
                 ) {
                     if (!Double.isNaN(gom) && !Double.isNaN(odo)) {
                         realRangeReference = odo + gom;
                     }
                 }
                 if (Double.isNaN(realRangeReference)) {
                     return Double.NaN;
                 }
                 double delta = realRangeReference - odo - gom;
                 if (delta > 12.0 || delta < -12.0) {
                     realRangeReference = odo + gom;
                     delta = 0.0;
                 }
                 return delta;
             }
         });*/
    }

    mutating func addVirtualFieldRealDeltaNoReset() {
        // get last value for realRange from internal database
        // TODO: if realRangeReference2 == Double.nan {
//            realRangeReference2 = CanzeDataSource.getInstance().getLast(Sid.RangeEstimate)
//        }

        addVirtualFieldCommon(virtualId: "6108", decimals: nil, unit: "km", dependantSids: Sid.EVC_Odometer + ";" + Sid.RangeEstimate) // , new VirtualFieldAction() {
        /* @Override
             public double updateValue(HashMap<String, Field> dependantFields) {
                 Field privateField;
                 if ((privateField = dependantFields.get(Sid.EVC_Odometer)) == null) return Double.NaN;
                 double odo = privateField.getValue();
                 if ((privateField = dependantFields.get(Sid.RangeEstimate)) == null) return Double.NaN;
                 double gom = privateField.getValue();

                 //MainActivity.debug("realRange ODO: "+odo);
                 //MainActivity.debug("realRange GOM: "+gom);

                 // timestamp of last inserted dot in MILLISECONDS
                 long lastInsertedTime = CanzeDataSource.getInstance().getLastTime(Sid.RangeEstimate);
                 if (    // timeout of 15 minutes
                         (Calendar.getInstance().getTimeInMillis() - lastInsertedTime > 15 * 60 * 1000)
                                 ||
                                 Double.isNaN(realRangeReference2)
                 ) {
                     if (!Double.isNaN(gom) && !Double.isNaN(odo)) {
                         realRangeReference2 = odo + gom;
                     }
                 }
                 if (Double.isNaN(realRangeReference2)) {
                     return Double.NaN;
                 }
                 double delta = realRangeReference2 - odo - gom;
                 if (delta > 500.0 || delta < -500.0) {
                     realRangeReference2 = odo + gom;
                     delta = 0.0;
                 }
                 return delta;
             }
         });*/
    }

    mutating func addVirtualFieldPilotAmp() {
        if AppSettings.shared.useIsoTpFields || Utils.isPh2() {
            addVirtualFieldCommon(virtualId: "610d", decimals: nil, unit: "A", dependantSids: Sid.ACPilotDutyCycle) // , new VirtualFieldAction() {
            /* @Override
                 public double updateValue(HashMap<String, Field> dependantFields) {
                     Field privateField;
                     if ((privateField = dependantFields.get(Sid.ACPilotDutyCycle)) == null)
                         return Double.NaN;
                     double dutyCycle = privateField.getValue();
                     return dutyCycle < 80.0 ? dutyCycle * 0.6 : (dutyCycle - 64.0) * 2.5;
                 }
             });*/

        } else {
            addVirtualFieldCommon(virtualId: "610d", decimals: nil, unit: "A", dependantSids: Sid.ACPilotAmps) // , new VirtualFieldAction() {
            /* @Override
                 public double updateValue(HashMap<String, Field> dependantFields) {
                     Field privateField;
                     if ((privateField = dependantFields.get(Sid.ACPilotAmps)) == null)
                         return Double.NaN;
                     return privateField.getValue();
                 }
             });*/
        }
    }

    mutating func addVirtualFieldGps() {
        /* TODO:
         if locationManager == nil {
             locationManager = (LocationManager) MainActivity.getInstance().getBaseContext().getSystemService(Context.LOCATION_SERVICE);
             locationListener = new MyLocationListener();
         }*/
        var gpsField = getBySID(sid: "800.610e.24")
        if gpsField == nil {
            let frame = Frames.getInstance.getById(id: 0x800)
            gpsField = Field(sid: "", frame: frame, from: 24, to: 31, resolution: 1, offset: 0, decimals: 0, unit: "coord", responseId: "610e", options: 0xaff, name: "GPS", list: "")
            fields.append(gpsField!)
            fieldsBySid["800.610e.24"] = gpsField
        }
    }

    func virtualFieldPropelGps(startStop: Bool) {
        /* TODO:
         if (locationManager == null) return;
         // yes I know, this is the brute force approach...
         try {
             if (startStop) {
                 if (locationManager.isProviderEnabled(LocationManager.GPS_PROVIDER) ) {
                     locationManager.requestLocationUpdates(LocationManager.GPS_PROVIDER, 5000, 10, locationListener);
                 } else {
                     MainActivity.toast(MainActivity.TOAST_NONE, "Can't start location. Please switch on location services");
                 }
             } else {
                 locationManager.removeUpdates (locationListener);
             }
         } catch (SecurityException e) {
             MainActivity.toast(MainActivity.TOAST_NONE, "Can't start location. Please give CanZE location permission");
         }
          */
    }

    func getBySID(sid: String) -> Field? {
        return fieldsBySid[sid.lowercased()]
    }

    func trim(s: String) -> String {
        return s.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
