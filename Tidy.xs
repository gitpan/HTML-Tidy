#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <tidy.h>
#include <buffio.h>
#include <stdio.h>
#include <errno.h>

MODULE = HTML::Tidy         PACKAGE = HTML::Tidy

SV *
_tidy_messages(input)
    INPUT:
        const char *input
    CODE:
        TidyBuffer errbuf = {0};
        TidyDoc tdoc = tidyCreate();                   // Initialize "document"

        int rc;

        rc = tidySetErrorBuffer( tdoc, &errbuf );      // Capture diagnostics
        if ( rc >= 0 )
            rc = tidyParseString( tdoc, input );       // Parse the input

        if ( rc >= 0 ) {
            const uint totalErrors = tidyErrorCount(tdoc) + tidyWarningCount(tdoc) + tidyAccessWarningCount(tdoc);
            const char *str = totalErrors ? (const char *)errbuf.bp : "";
            if ( str ) {
                RETVAL = newSVpvn( str, strlen(str) );
            }
            else {
                RETVAL = &PL_sv_undef;
            }
        }
        else {
            XSRETURN_UNDEF;
        }

        tidyBufFree( &errbuf );
        tidyRelease( tdoc );

    OUTPUT:
        RETVAL


void
_tidy_clean(input, configfile)
    INPUT:
        const char *input
        const char *configfile
    PPCODE:
        TidyBuffer errbuf = {0};
        TidyBuffer output = {0};

        TidyDoc tdoc = tidyCreate();                // Initialize "document"
        int rc;

        if ( configfile && *configfile )
            rc = tidyLoadConfig( tdoc, configfile );

        rc = tidyOptSetInt( tdoc, TidyWrapLen, 0 ); // Don't word-wrap
        if ( rc >= 0 )
          rc = tidySetErrorBuffer( tdoc, &errbuf );  // Capture diagnostics
        if ( rc >= 0 )
            rc = tidyParseString( tdoc, input );   // Parse the input
        if ( rc >= 0 )
            rc = tidyCleanAndRepair(tdoc);
        if ( rc > 1 )
            rc = tidyOptSetBool( tdoc, TidyForceOutput, yes ) ? rc : -1;
        if ( rc >= 0)
            rc = tidySaveBuffer( tdoc, &output );
        if ( rc >= 0)
            rc = tidyRunDiagnostics( tdoc );
        if ( rc >= 0 ) {
            const char *str = (const char *)output.bp;
            if ( str )
                XPUSHs( sv_2mortal(newSVpvn(str, strlen(str))) );

            if ( errbuf.bp )
                XPUSHs( sv_2mortal(newSVpvn(errbuf.bp, strlen(errbuf.bp))) );
        }
        else {
            XSRETURN_UNDEF;
        }

        tidyBufFree( &output );
        tidyBufFree( &errbuf );
        tidyRelease( tdoc );

