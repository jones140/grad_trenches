/*
 * Author: Garth 'L-H' de Wet, Ruthberg, edited by commy2 for better MP and eventual AI support, esteldunedain
 * Continue process of digging trench.
 *
 * Arguments:
 * 0: trench <OBJECT>
 * 1: unit <OBJECT>
 *
 * Return Value:
 * None
 *
 * Example:
 * [TrenchObj, ACE_player] call ace_trenches_fnc_continueDiggingTrench
 *
 * Public: No
 */
#include "script_component.hpp"

params ["_trench", "_unit"];
TRACE_2("continueDiggingTrench",_trench,_unit);

private _actualProgress = _trench getVariable ["ace_trenches_progress", 0];
if(_actualProgress == 1) exitWith {};

// Mark trench as being worked on
_trench setVariable ["ace_trenches_digging", true, true];

private _digTime = missionNamespace getVariable [getText (configFile >> "CfgVehicles" >> (typeof _trench) >>"ace_trenches_diggingDuration"), 20];
private _digTimeLeft = _digTime * (1 - _actualProgress);

private _placeData = _trench getVariable ["ace_trenches_placeData", [[], []]];
_placeData params ["_basePos", "_vecDirAndUp"];

private _trenchId = _unit getVariable ["ace_trenches_isDiggingId", -1];
if(_trenchId < 0) then {
    _trenchId = ace_trenches_trenchId;
    _unit setVariable ["ace_trenches_isDiggingId", _trenchId, true];
    ace_trenches_trenchId = ace_trenches_trenchId + 1;
};

// Create progress bar
private _fnc_onFinish = {
    (_this select 0) params ["_unit", "_trench"];
    _unit setVariable ["ace_trenches_isDiggingId", -1, true];
    _trench setVariable ["ace_trenches_digging", false, true];

    // Save progress global
    private _progress = _trench getVariable ["ace_trenches_progress", 0];
    _trench setVariable ["ace_trenches_progress", _progress, true];

    // Reset animation
    [_unit, "", 1] call ace_common_fnc_doAnimation;
};
private _fnc_onFailure = {
    (_this select 0) params ["_unit", "_trench"];
    _unit setVariable ["ace_trenches_isDiggingId", -1, true];
    _trench setVariable ["ace_trenches_digging", false, true];

    // Save progress global
    private _progress = _trench getVariable ["ace_trenches_progress", 0];
    _trench setVariable ["ace_trenches_progress", _progress, true];

    // Reset animation
    [_unit, "", 1] call ace_common_fnc_doAnimation;
};
[(_digTimeLeft + 0.5), [_unit, _trench], _fnc_onFinish, _fnc_onFailure, localize "STR_ace_trenches_DiggingTrench"] call ace_common_fnc_progressBar;

if(_actualProgress == 0) then {
    [_unit, _trench, _trenchId, _basePos vectorDiff [0, 0, 1.0], _vecDirAndUp, _actualProgress] call ace_trenches_fnc_setTrenchPlacement;

    //Remove grass
    {
        private _trenchGrassCutter = createVehicle ["Land_ClutterCutter_medium_F", [0, 0, 0], [], 0, "NONE"];
        private _cutterPos = AGLToASL (_trench modelToWorld _x);
        _cutterPos set [2, getTerrainHeightASL _cutterPos];
        _trenchGrassCutter setPosASL _cutterPos;
        deleteVehicle _trenchGrassCutter;
    } foreach getArray (configFile >> "CfgVehicles" >> (typeof _trench) >> "ace_trenches_grassCuttingPoints");
};

private _progressLeft = (_actualProgress * 10) + 1;

for "_i" from _progressLeft to 10 do {
    private _vectorDiffZ = 1 - (_i / 10);
    private _delay = _digTime * ((_i / 10) - _actualProgress);
    private _progress = _i / 10;
    [FUNC(setTrenchPlacement), [_unit, _trench, _trenchId, _basePos vectorDiff [0, 0, _vectorDiffZ], _vecDirAndUp, _progress, _digTime], _delay] call CBA_fnc_waitAndExecute;
};

// Play animation
[_unit, "AinvPknlMstpSnonWnonDnon_medic4"] call ace_common_fnc_doAnimation;