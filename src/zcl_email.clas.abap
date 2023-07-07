"! <p class="shorttext synchronized" lang="en">Email</p>
CLASS zcl_email DEFINITION
  PUBLIC
  INHERITING FROM cl_bcs_message
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    "! <p class="shorttext synchronized" lang="en">set email body from so10 text</p>
    METHODS set_body_so10
      IMPORTING
        !text_name TYPE tdobname
        !language  TYPE bcs_language DEFAULT sy-langu
        !doctype   TYPE bcs_doctype DEFAULT 'txt'
        !tdid      TYPE thead-tdid DEFAULT 'ST'
        !tdobject  TYPE thead-tdobject DEFAULT 'TEXT' .
    "! <p class="shorttext synchronized" lang="en">set email body and subject from email Template id</p>
    METHODS set_subject_body_template
      IMPORTING
        !template_id TYPE smtg_tmpl_id
        !language    TYPE bcs_language DEFAULT sy-langu
        !doctype     TYPE bcs_doctype DEFAULT 'txt'
        !data        TYPE any .
    "! <p class="shorttext synchronized" lang="en">set placeholder</p>
    METHODS set_placeholder
      IMPORTING
        !placeholder_name  TYPE string
        !placeholder_value TYPE string .
    "! <p class="shorttext synchronized" lang="en">Add recipient email id from SAP DL</p>
    METHODS add_dl_recipients
      IMPORTING
        !dlinam     TYPE so_dli_nam
        !shared_dli TYPE so_text001 DEFAULT space
        !copy       TYPE bcs_copy OPTIONAL .
    "! <p class="shorttext synchronized" lang="en">validate email id</p>
    CLASS-METHODS is_emailid_valid
      IMPORTING
        !emailid                TYPE ad_smtpadr
      RETURNING
        VALUE(is_emailid_valid) TYPE abap_bool .
    METHODS set_placeholder_itab
      IMPORTING
        !placeholder_name       TYPE string
        VALUE(placeholder_itab) TYPE STANDARD TABLE
        !it_fcat                TYPE lvc_t_fcat OPTIONAL
        !table_title            TYPE w3_text OPTIONAL .
    METHODS constructor
      IMPORTING
        !template_id      TYPE smtg_tmpl_id
        !language         TYPE bcs_language DEFAULT sy-langu
        !doctype          TYPE bcs_doctype DEFAULT 'txt'
        !data             TYPE any
        !subject          TYPE string OPTIONAL
        !att_doctype      TYPE bcs_doctype OPTIONAL
        !att_filename     TYPE bcs_filename OPTIONAL
        !att_contents_txt TYPE string OPTIONAL
        !att_contents_bin TYPE xstring OPTIONAL
        !address          TYPE bcs_address OPTIONAL
        !visible_name     TYPE bcs_visname DEFAULT 'SAPADMIN'.
  PROTECTED SECTION.
  PRIVATE SECTION.
    DATA: mv_symbols_start TYPE string VALUE '{{',
          mv_symbols_end   TYPE string VALUE '}}',
          mv_address       TYPE bcs_address,
          mv_visible_name  TYPE bcs_visname,
          mv_subject       TYPE string,
          mo_document      TYPE REF TO cl_document_bcs.

    DATA gt_data_key TYPE if_smtg_email_template=>ty_gt_data_key .

    "! <p class="shorttext synchronized" lang="en">Replace placeholder than CDS</p>
    METHODS replace_placeholder
      IMPORTING
        !replace_string TYPE string
      RETURNING
        VALUE(result)   TYPE string .
    METHODS set_data_key
      IMPORTING
        !data TYPE any.
    METHODS set_default_sender.
    METHODS set_recipients
      IMPORTING
        !template_id TYPE smtg_tmpl_id.
ENDCLASS.



CLASS zcl_email IMPLEMENTATION.


  METHOD add_dl_recipients.
    DATA :
      li_dli       TYPE TABLE OF sodlienti1.

    CALL FUNCTION 'SO_DLI_READ_API1'
      EXPORTING
        dli_name                   = dlinam
*       DLI_ID                     = ' '
        shared_dli                 = shared_dli
* IMPORTING
*       DLI_DATA                   =
      TABLES
        dli_entries                = li_dli
      EXCEPTIONS
        dli_not_exist              = 1
        operation_no_authorization = 2
        parameter_error            = 3
        x_error                    = 4
        OTHERS                     = 5.
    IF sy-subrc = 0.
      LOOP AT li_dli INTO DATA(ls_dli).
        add_recipient(
          EXPORTING
            iv_address      = CONV #( ls_dli-member_adr )  " Communication Address (for INT, FAX, SMS, and so on)
*           iv_commtype     = 'INT'                     " Communication Type
            iv_visible_name = CONV #( ls_dli-member_nam )  " Display Name of an Address
            iv_copy         = copy              " Copy Recipients (None, CC, BCC)
*           iv_fax_country  =                  " Country for Telephone/Fax Number
        ).
      ENDLOOP.
    ENDIF.

  ENDMETHOD.


  METHOD is_emailid_valid.
    DATA ls_address   TYPE sx_address.
    ls_address-type = 'INT'.
    ls_address-address = emailid.

    CALL FUNCTION 'SX_INTERNET_ADDRESS_TO_NORMAL'
      EXPORTING
        address_unstruct    = ls_address
      EXCEPTIONS
        error_address_type  = 1
        error_address       = 2
        error_group_address = 3
        OTHERS              = 4.
    IF sy-subrc EQ 0.
      is_emailid_valid = abap_true.
    ENDIF.
  ENDMETHOD.


  METHOD replace_placeholder.
    result = replace_string.
    LOOP AT gt_data_key INTO DATA(ls_data_key).
      REPLACE ALL OCCURRENCES OF ls_data_key-name IN result WITH ls_data_key-value.
    ENDLOOP.
  ENDMETHOD.


  METHOD set_body_so10.
*get Email body from so10 text.
    DATA :
      li_lines    TYPE TABLE OF tline,
      lw_lines    TYPE tline,
      lw_mailbody TYPE soli.

    DATA: lv_no_of_lines LIKE sy-tabix,
          lv_changed(1)  TYPE c.

    DATA: lv_header TYPE thead.
    DATA : lv_mailbody TYPE string.

    IF text_name IS NOT INITIAL.

      CALL FUNCTION 'READ_TEXT'
        EXPORTING
          id                      = tdid "'ST'
          language                = language
          name                    = text_name
          object                  = tdobject "'TEXT'
        IMPORTING
          header                  = lv_header
        TABLES
          lines                   = li_lines
        EXCEPTIONS
          id                      = 1
          language                = 2
          name                    = 3
          not_found               = 4
          object                  = 5
          reference_check         = 6
          wrong_access_to_archive = 7
          OTHERS                  = 8.

      IF sy-subrc <> 0.
*      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
*              WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      ELSE.

        LOOP AT gt_data_key INTO DATA(ls_data_key).
          CALL FUNCTION 'TEXT_SYMBOL_SETVALUE'
            EXPORTING
              name  = ls_data_key-name
              value = ls_data_key-value.
        ENDLOOP.

        DESCRIBE TABLE li_lines LINES lv_no_of_lines.

        CALL FUNCTION 'TEXT_SYMBOL_REPLACE'
          EXPORTING
            endline       = lv_no_of_lines
            header        = lv_header
            init          = ' '
            option_dialog = ' '
            program       = sy-cprog
          IMPORTING
            changed       = lv_changed
            newheader     = lv_header
          TABLES
            lines         = li_lines.

        LOOP AT li_lines INTO lw_lines.
          lv_mailbody = lv_mailbody && lw_lines-tdline.
        ENDLOOP.

        set_main_doc(
          EXPORTING
            iv_contents_txt = lv_mailbody      " Main Documet, First Body Part
*           iv_contents_bin =                 " Main Document, First Body Part (Binary)
            iv_doctype      = doctype          " Document Category
*           iv_codepage     =                 " Character Set of a Document
        ).

      ENDIF.
    ENDIF.

  ENDMETHOD.


  METHOD set_placeholder.
    APPEND  VALUE #( name = placeholder_name
                     value = placeholder_value )
       TO gt_data_key.
  ENDMETHOD.


  METHOD set_placeholder_itab.

    DATA :
      table_attributes  TYPE w3html,
      placeholder_value TYPE string,
      mt_fcat           TYPE lvc_t_fcat, " Fieldcatalog
      mt_data           TYPE REF TO data,
      mo_salv_table     TYPE REF TO cl_salv_table,
      mo_columns        TYPE REF TO cl_salv_columns_table,
      mo_aggreg         TYPE REF TO cl_salv_aggregations,
      ls_header         TYPE w3head,
      lt_header         TYPE STANDARD TABLE OF w3head,   "Header
      lt_fields         TYPE STANDARD TABLE OF w3fields, "Fields
      lt_html           TYPE STANDARD TABLE OF w3html.     "Html

    FIELD-SYMBOLS:
      <tab> TYPE STANDARD TABLE.

    GET REFERENCE OF placeholder_itab INTO mt_data.

*if we didn't pass fieldcatalog we need to create it
    IF it_fcat[] IS INITIAL.
      ASSIGN mt_data->* TO <tab>.
      TRY .
          cl_salv_table=>factory(
            EXPORTING
              list_display = abap_false
            IMPORTING
              r_salv_table = mo_salv_table
            CHANGING
              t_table      = <tab> ).
        CATCH cx_salv_msg.

      ENDTRY.
      "get colums & aggregation infor to create fieldcat
      mo_columns  = mo_salv_table->get_columns( ).
      mo_aggreg   = mo_salv_table->get_aggregations( ).
      mt_fcat = cl_salv_controller_metadata=>get_lvc_fieldcatalog(
        r_columns      = mo_columns
        r_aggregations = mo_aggreg ).
    ELSE.
*else we take the one we passed
      mt_fcat[] = it_fcat[].
    ENDIF.

    LOOP AT mt_fcat INTO DATA(ls_fcat).
*-Populate the Column Headings
      IF ls_fcat-reptext IS NOT INITIAL.
        ls_header-text = ls_fcat-reptext.
      ELSEIF ls_fcat-scrtext_m IS NOT INITIAL.
        ls_header-text = ls_fcat-scrtext_m.
      ELSEIF ls_fcat-scrtext_s IS NOT INITIAL.
        ls_header-text = ls_fcat-scrtext_s.
      ELSEIF ls_fcat-scrtext_l IS NOT INITIAL.
        ls_header-text = ls_fcat-scrtext_l.
      ENDIF.

      CALL FUNCTION 'WWW_ITAB_TO_HTML_HEADERS'
        EXPORTING
          field_nr = sy-tabix
          text     = ls_header-text
          fgcolor  = 'black' "remove this hard code
          bgcolor  = 'White' "remove this hard code
        TABLES
          header   = lt_header.

      CALL FUNCTION 'WWW_ITAB_TO_HTML_LAYOUT'
        EXPORTING
          field_nr = sy-tabix
          fgcolor  = 'black' "remove this hard code
        TABLES
          fields   = lt_fields.

    ENDLOOP.

    "-Title of the Display
    ls_header-text = table_title. "'Flights Details' .
*    ls_header-font = 'Arial'.
*    ls_header-size = '2'.

    table_attributes = 'border="1" cellpadding="3" style="border-collapse:collapse"'.

    CALL FUNCTION 'WWW_ITAB_TO_HTML'
      EXPORTING
        table_attributes = table_attributes
        table_header     = ls_header
      TABLES
        html             = lt_html
        fields           = lt_fields
        row_header       = lt_header
        itable           = placeholder_itab.

    LOOP AT lt_html INTO DATA(ls_html).
      placeholder_value =  placeholder_value && ls_html-line.
    ENDLOOP.


    APPEND  VALUE #( name = placeholder_name
                     value = placeholder_value )
       TO gt_data_key.
  ENDMETHOD.


  METHOD set_subject_body_template.
    SELECT SINGLE @abap_true INTO @DATA(lv_exists) FROM ztemail_template
      WHERE smtg_tmpl_id = @template_id.
    CHECK sy-subrc = 0.
    set_recipients( template_id ).
    set_data_key( data ).
    set_default_sender( ).
    " read headers
    SELECT SINGLE cds_view FROM smtg_tmpl_hdr
      INTO @DATA(lv_cds_view)
      WHERE id      EQ @template_id
        AND version EQ 'A'. "GC_VERSION_ACTIVE
    IF sy-subrc EQ 0.
      IF lv_cds_view IS NOT INITIAL.
        DATA(lt_data_key) = gt_data_key.
      ENDIF.

      TRY.
          DATA(lo_email_api) = cl_smtg_email_api=>get_instance( iv_template_id = template_id ).

          lo_email_api->render(
            EXPORTING
              iv_language  = language
              it_data_key  = lt_data_key
            IMPORTING
              ev_subject   = DATA(lv_subject)
              ev_body_html = DATA(lv_body_html)
              ev_body_text = DATA(lv_body_text) ).

        CATCH cx_smtg_email_common INTO DATA(ex). " E-Mail API Exceptions
      ENDTRY.

      IF doctype EQ 'HTM'.
        DATA(lv_mailbody) = lv_body_html.
      ELSE.
        lv_mailbody = lv_body_text.
      ENDIF.

      IF lv_cds_view IS INITIAL.
        lv_mailbody = replace_placeholder( lv_mailbody ).
        lv_subject = replace_placeholder( lv_subject ).
      ENDIF.

      set_subject( lv_subject ).

      set_main_doc(
        EXPORTING
          iv_contents_txt = lv_mailbody      " Main Documet, First Body Part
          iv_doctype      = doctype ).       " Document Category

    ELSE.
      IF mv_subject IS NOT INITIAL.
        set_subject( mv_subject ).
      ENDIF.
      set_main_doc(
        EXPORTING
          iv_contents_txt = CONV #( data )   " Main Documet, First Body Part
          iv_doctype      = doctype ).       " Document Category

    ENDIF.
  ENDMETHOD.


  METHOD set_data_key.
    FIELD-SYMBOLS: <fs_any> TYPE any,
                   <fs_tab> TYPE STANDARD TABLE.
    DATA: lrf_result_descr TYPE REF TO cl_abap_structdescr.
    TRY.
        lrf_result_descr ?=  cl_abap_datadescr=>describe_by_data( data ).
        LOOP AT lrf_result_descr->components INTO DATA(ls_components).
          CASE ls_components-type_kind.
            WHEN cl_abap_structdescr=>typekind_table.
              ASSIGN COMPONENT ls_components-name OF STRUCTURE data TO <fs_tab>.
              CHECK sy-subrc = 0.
              set_placeholder_itab( placeholder_name = |{ mv_symbols_start }{  ls_components-name }{ mv_symbols_end }|  placeholder_itab = <fs_tab> ).
            WHEN OTHERS.
              ASSIGN COMPONENT ls_components-name OF STRUCTURE data TO <fs_any>.
              CHECK sy-subrc = 0.
              set_placeholder( placeholder_name = |{ mv_symbols_start }{  ls_components-name }{ mv_symbols_end }|  placeholder_value = CONV #( <fs_any> ) ).
          ENDCASE.
        ENDLOOP.
      CATCH cx_root.
    ENDTRY.
  ENDMETHOD.


  METHOD set_recipients.
    SELECT smtp_addr
      FROM usr21 AS a
      JOIN adr6 AS b ON a~addrnumber = b~addrnumber AND a~persnumber = b~persnumber
      JOIN ztemail_attn AS c ON c~bname = a~bname AND c~smtg_tmpl_id = @template_id
      WHERE b~smtp_addr IS NOT INITIAL
      INTO TABLE @DATA(lt_addr).
    CHECK sy-subrc = 0.
    LOOP AT lt_addr INTO DATA(ls_addr).
      add_recipient( iv_address = CONV #( ls_addr-smtp_addr ) ).
    ENDLOOP.
  ENDMETHOD.

  METHOD constructor.
    super->constructor( ).
    mv_address      = address.
    mv_visible_name = visible_name.
    IF subject IS SUPPLIED.
      mv_subject = subject.
    ENDIF.

    set_subject_body_template( template_id = template_id
                               language    = language
                               doctype     = doctype
                               data        = data ).
    IF att_contents_txt IS SUPPLIED OR att_contents_bin IS SUPPLIED.
      add_attachment( iv_doctype      = att_doctype
                      iv_filename     = |{ att_filename  }.{ att_doctype }|
                      iv_contents_txt = att_contents_txt
                      iv_contents_bin = att_contents_bin ).
    ENDIF.
    set_send_immediately( abap_false ).

  ENDMETHOD.
  METHOD set_default_sender.
    IF mv_address IS INITIAL.
      SELECT SINGLE smtpuser INTO @mv_address FROM sxnodes WHERE node_type = 'S' AND active = 'X'.
    ENDIF.
    mv_address = to_lower( mv_address ).
  ENDMETHOD.

ENDCLASS.
