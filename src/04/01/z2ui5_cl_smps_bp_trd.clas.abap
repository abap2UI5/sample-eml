"! <p class="shorttext synchronized">abap2UI5 EML sample - behavior pool (draft)</p>
"! Behavior pool of the business object z2ui5_r_smps_trd. The implementation
"! lives in the local types include, that is where RAP expects the handler
"! classes - see z2ui5_cl_smps_bp_trd.clas.locals_imp.abap.
"!
"! FOR BEHAVIOR OF is what makes this a behavior pool instead of an ordinary
"! abstract final class. Without it RAP finds no handler at all and every EML
"! statement dies on the first one it looks for - the global authorization.
CLASS z2ui5_cl_smps_bp_trd DEFINITION PUBLIC ABSTRACT FINAL FOR BEHAVIOR OF z2ui5_r_smps_trd.
ENDCLASS.


CLASS z2ui5_cl_smps_bp_trd IMPLEMENTATION.
ENDCLASS.
