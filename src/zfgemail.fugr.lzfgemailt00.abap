*---------------------------------------------------------------------*
*    view related data declarations
*---------------------------------------------------------------------*
*...processing: ZTEMAIL_ATTN....................................*
DATA:  BEGIN OF STATUS_ZTEMAIL_ATTN                  .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_ZTEMAIL_ATTN                  .
CONTROLS: TCTRL_ZTEMAIL_ATTN
            TYPE TABLEVIEW USING SCREEN '9010'.
*...processing: ZTEMAIL_TEMPLATE................................*
DATA:  BEGIN OF STATUS_ZTEMAIL_TEMPLATE              .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_ZTEMAIL_TEMPLATE              .
CONTROLS: TCTRL_ZTEMAIL_TEMPLATE
            TYPE TABLEVIEW USING SCREEN '9000'.
*.........table declarations:.................................*
TABLES: *ZTEMAIL_ATTN                  .
TABLES: *ZTEMAIL_TEMPLATE              .
TABLES: ZTEMAIL_ATTN                   .
TABLES: ZTEMAIL_TEMPLATE               .

* general table data declarations..............
  INCLUDE LSVIMTDT                                .
