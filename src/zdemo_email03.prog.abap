*&---------------------------------------------------------------------*
*& Report ZDEMO_EMAIL3
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zdemo_email03.
TRY.
    NEW zcl_email(
      template_id = 'ZET_DEMO02' "Email body from Email template
      doctype = 'HTM'
      data = '欢迎登录系统'
      subject = '欢迎登录'
      att_doctype = 'TXT' " attachment..
      att_filename = 'My Text File'
      att_contents_txt = `My text file contents` )->send( ).
  CATCH cx_bcs_send INTO DATA(ex).
    MESSAGE ex->get_text( ) TYPE 'S'.

ENDTRY.
