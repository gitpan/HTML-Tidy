#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <tidy.h>
#include <buffio.h>
#include <stdio.h>
#include <errno.h>

MODULE = HTML::Tidy		PACKAGE = HTML::Tidy		

SV *
_calltidy(input)
    INPUT:
        char *input
    CODE:
        TidyBuffer errbuf = {0};
        TidyDoc tdoc = tidyCreate();                     // Initialize "document"

        int rc;

        rc = tidySetErrorBuffer( tdoc, &errbuf );      // Capture diagnostics
        if ( rc >= 0 )
            rc = tidyParseString( tdoc, input );           // Parse the input

        if ( rc >= 0 ) {
            const uint totalErrors = tidyErrorCount(tdoc) + tidyWarningCount(tdoc) + tidyAccessWarningCount(tdoc);
            char *str = totalErrors ? (char *)errbuf.bp : "";
            RETVAL = newSVpvn( str, strlen(str) );
        } else {
            XSRETURN_UNDEF;
        }

        tidyBufFree( &errbuf );
        tidyRelease( tdoc );

    OUTPUT:
        RETVAL

