*&---------------------------------------------------------------------*
*& Report ZDEMO_EMAIL3
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zdemo_email02.
TRY.
    NEW zcl_email(
      template_id = 'ZET_DEMO02' "Email body from Email template
      doctype = 'HTM'
      data = '欢迎登录系统'
      subject = '欢迎登录' )->send( ).
  CATCH cx_bcs_send INTO DATA(ex).
    MESSAGE ex->get_text( ) TYPE 'S'.

ENDTRY.
