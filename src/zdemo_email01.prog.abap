*&---------------------------------------------------------------------*
*& Report ZDEMO_EMAIL3
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zdemo_email01.
"send email with HTML body using email template
TYPES: BEGIN OF ty_tab,
         posnr  TYPE vbap-posnr,
         matnr  TYPE vbap-matnr,
         arktx  TYPE vbap-arktx,
         kwmeng TYPE vbap-kwmeng,
         vrkme  TYPE vbap-vrkme,
         price  TYPE prcd_elements-kbetr,
         total  TYPE prcd_elements-kwert,
       END OF ty_tab,
       tt_tab TYPE STANDARD TABLE OF ty_tab WITH DEFAULT KEY.

TYPES: BEGIN OF ty_data,
         vbeln  TYPE vbak-vbeln,
         ernam  TYPE vbak-ernam,
         it_tab TYPE tt_tab,
       END OF ty_data.
DATA: ls_data TYPE ty_data.
TRY.

    DATA lv_vbeln TYPE vbeln VALUE '1120000019'.

    SELECT a~vbeln,a~ernam,b~posnr,b~matnr,b~arktx,b~kwmeng,b~vrkme,c~kbetr AS price, c~kwert AS total
      FROM vbak AS a
      JOIN vbap AS b ON a~vbeln = b~vbeln
      JOIN prcd_elements AS c ON a~knumv = c~knumv AND b~posnr = c~kposn AND c~kschl = 'ZPR1'
      WHERE a~vbeln = @lv_vbeln
      INTO TABLE @DATA(lt_vbap).
    IF sy-subrc = 0.
      ls_data-vbeln = lt_vbap[ 1 ]-vbeln.
      ls_data-ernam = lt_vbap[ 1 ]-ernam.
      ls_data-it_tab[] = CORRESPONDING #( lt_vbap[] ).

      NEW zcl_email(
        template_id = 'ZET_DEMO01' "Email body from Email template
        doctype = 'HTM'
        data = ls_data )->send( ).
    ENDIF.
  CATCH cx_bcs_send INTO DATA(ex).
    MESSAGE ex->get_text( ) TYPE 'S'.

ENDTRY.
