unit Ldist;
interface
{
//---------------------------------------------------------------------------
// is_alike()
//
// Purpose: Compairs two words to see if they are similar.  Calculates a
//          threshold from the first string.  Tests the difference in the
//          string lengths to see if it is less than this threshold.  If so,
//          then the L Distance is calculated.  If the threshold is greater
//          than the L Distance, the words are a match.
//
// Inputs:  char *str1, *str2 - input strings (words) to compare
//          int *threshold    - pointer to return threshold variable
//          int *ldist        - pointer to return L Distance variable
//
// Outputs: int threshold - The calculated threshold.
//          int ldist     - The calculated L Distance is returned to the
//                          caller.  Set to LENGTH_MISMATCH if the length
//                          test failed.
//
// Returns: ALIKE if the two words are matched, otherwise NOT_ALIKE
//
// (values in all CAPS are defined in the LDIST.H header file)
//
//---------------------------------------------------------------------------
}
function is_alike(str1, str2 : Pchar; var threshold : integer;
                                      var ldist: integer): boolean;

implementation
{$L ldist.obj}
function is_alike(str1, str2 : Pchar; var threshold: integer;
                                      var ldist: integer): boolean; external;
function l_dist_list: integer; external;
{$L NSTRLEN.OBJ}
procedure _strlen; external;
end.
