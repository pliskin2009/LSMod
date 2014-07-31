class LSModFamilyInfoCustom extends Object;

var float AMaxFallSpeed;
var float MMaxFallSpeed;
var float KMaxFallSpeed;
var float VMaxFallSpeed;
var float RMaxFallSpeed;


var bool AbCanJetUp;
var bool MbCanJetUp;
var bool KbCanJetUp;
var bool VbCanJetUp;
var bool RbCanJetUp;

///////////////////////////Stores the default status of the different classes (that are not declared in the parent AOCFamilyInfo)/////

static function float GetCustomClassFloatStatus (EAOCClass FamilyClass, string VarName)
{
	if(VarName == "MaxFallSpeed")
	{
		Switch(FamilyClass)
		{
		case ECLASS_Archer:
			return default.AMaxFallSpeed;
		case ECLASS_ManAtArms:
			return default.MMaxFallSpeed;
		case ECLASS_Knight:
			return default.KMaxFallSpeed;
		case ECLASS_Vanguard:
			return default.VMaxFallSpeed;
		case ECLASS_King:
			return default.RMaxFallSpeed;
		default:
			return 0.0;
		}
	}
	else return 0.0;
}

static function bool GetCustomClassBoolStatus (EAOCClass FamilyClass, string VarName)
{
	if(VarName == "bCanJetUp")
	{
		Switch(FamilyClass)
		{
		case ECLASS_Archer:
			return default.AbCanJetUp;
		case ECLASS_ManAtArms:
			return default.MbCanJetUp;
		case ECLASS_Knight:
			return default.KbCanJetUp;
		case ECLASS_Vanguard:
			return default.VbCanJetUp;
		case ECLASS_King:
			return default.RbCanJetUp;
		default:
			return false;
		}
	}
	else return false;
}

DefaultProperties
{
/////////ARCHER
AMaxFallSpeed =  805.0

AbCanJetUp = FALSE

/////////MAA
MMaxFallSpeed = 1400.0

MbCanJetUp = TRUE



////////KNIGHT
KMaxFallSpeed = 1400.0

KbCanJetUp = FALSE



////////VANGUARD
VMaxFallSpeed = 1400.0

VbCanJetUp = TRUE





///////KING
RMaxFallSpeed =1400.0

RbCanJetUp = TRUE

}