// Levenstein Distance Algorithms Include Module
// Companion to the LDIST.C source file.
// Written initailly by R. Bruce Roberts, MCI Systems Engineering, 1/7/93
//

#define MAX_LDIST_LEN      40 // max word len to compair

#define ADDITION           1  // penality for needing to add a character
#define CHANGE             1  // penality for needing to modify a character
#define DELETION           1  // penality for needing to delete a character

#define ALIKE              1
#define NOT_ALIKE          0

#define LENGTH_MISMATCH    32767

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
int pascal far is_alike(char *str1, char *str2, int *threshold, int *ldist);


//---------------------------------------------------------------------------
// l_dist_list()
//
// Purpose: Compares a single string (word) against a list of strings (words)
//          and returns the top 'n' matches.  A top match is defined as ones
//          with the lowest L Distance.  The caller must allocate space for
//          the returned list of pointers and L Distances.  The caller also
//          sets the number of matches returned.  Matches will be sorted by
//          L Distance (lowest first) then by the order in the input list.
//
//          Note, processing will continue through the entire input list.
//          Only the best "match_limit" values will be retained.  In the
//          event of like L Distance values, the first will have presidence.
//          Also, only the first MAX_LDIST_LEN characters of the key and the
//          list strings will be compared.
//
// Inputs:  char *key       - input key to "look up"
//          char *list[]    - list of words to test against
//                            This list must be terminated with a null
//                            string as its last entry.
//          char *match[]   - this array is set to point to the entries in
//                            "list" that match the key string.
//          int dist[]      - L Distance values that correspond to the string
//                            pointed to by "match".
//          int match_limit - maximum number of matches to allow
//          int *threshold  - pointer to return threshold variable
//
// Outputs: char match[]  - Pointers to the matching strings in "list".  The
//                          indexs correspond to the L Distances in "dist".
//          int dist[]    - Contains the calculated L Distance values.  The
//                          indexs correspond to the string in "match".
//          int threshold - The calculated threshold.
//
// Returns: Number of matches found, 0..match_limit.
//
// (values in all CAPS are defined in the LDIST.H header file)
//
//---------------------------------------------------------------------------
int pascal far l_dist_list(char *key, char **list, char **match,
                int dist[], int match_limit, int *threshold);

