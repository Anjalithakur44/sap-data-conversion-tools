REPORT zprg_mm01_04
       NO STANDARD PAGE HEADING LINE-SIZE 255.

PARAMETERS: p_file TYPE localfile.

TYPES: BEGIN OF lty_data,
         matnr TYPE matnr,
         mbrsh TYPE mbrsh,
         mtart TYPE mtart,
         maktx TYPE maktx,
         meins TYPE meins,
       END OF lty_data.

DATA: lt_data  TYPE TABLE OF lty_data, "contains the legacy data
      lwa_data TYPE lty_data.

DATA: lv_file TYPE string.

DATA: lt_BDCDATA  TYPE TABLE OF bdcdata, "contains all recording steps along with the legacy data to be migrated
      lwa_bdcdata TYPE bdcdata.

*DATA: lt_MESSTAB  TYPE TABLE OF bdcmsgcoll,"contains message
*      lwa_messtab TYPE bdcmsgcoll.

*DATA: lv_messtab TYPE string.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_file.

  CALL FUNCTION 'F4_FILENAME' "module to choose the file's path after clicking on the f4 help
    EXPORTING
      program_name  = syst-cprog
      dynpro_number = syst-dynnr
      field_name    = ' '
    IMPORTING
      file_name     = p_file.

START-OF-SELECTION.

  lv_file = p_file. "explicit type casting p_file of type localfile into lv_file of string type.

  CALL FUNCTION 'GUI_UPLOAD' "module for reading the file
    EXPORTING
      filename                = lv_file
*     FILETYPE                = 'ASC'
      has_field_separator     = 'X'
*     HEADER_LENGTH           = 0
*     READ_BY_LINE            = 'X'
*     DAT_MODE                = ' '
*     CODEPAGE                = ' '
*     IGNORE_CERR             = ABAP_TRUE
*     REPLACEMENT             = '#'
*     CHECK_BOM               = ' '
*     VIRUS_SCAN_PROFILE      =
*     NO_AUTH_CHECK           = ' '
* IMPORTING
*     FILELENGTH              =
*     HEADER                  =
    TABLES
      data_tab                = lt_data
* CHANGING
*     ISSCANPERFORMED         = ' '
    EXCEPTIONS
      file_open_error         = 1
      file_read_error         = 2
      no_batch                = 3
      gui_refuse_filetransfer = 4
      invalid_type            = 5
      no_authority            = 6
      unknown_error           = 7
      bad_data_format         = 8
      header_not_allowed      = 9
      separator_not_allowed   = 10
      header_too_long         = 11
      unknown_dp_error        = 12
      access_denied           = 13
      dp_out_of_memory        = 14
      disk_full               = 15
      dp_timeout              = 16
      OTHERS                  = 17.
  IF sy-subrc <> 0.
* Implement suitable error handling here
  ENDIF.


  CALL FUNCTION 'BDC_OPEN_GROUP'
    EXPORTING
      client              = sy-mandt
*     DEST                = FILLER8
      group               = 'MM01_GRP'
*     HOLDDATE            = FILLER8
      keep                = 'X'
      user                = sy-uname
*     RECORD              = FILLER1
*     PROG                = SY-CPROG
*     DCPFM               = '%'
*     DATFM               = '%'
*     APP_AREA            = FILLER12
*     LANGU               = SY-LANGU
* IMPORTING
*     QID                 =
    EXCEPTIONS
      client_invalid      = 1
      destination_invalid = 2
      group_invalid       = 3
      group_is_locked     = 4
      holddate_invalid    = 5
      internal_error      = 6
      queue_error         = 7
      running             = 8
      system_lock_error   = 9
      user_invalid        = 10
      OTHERS              = 11.
  IF sy-subrc <> 0.
* Implement suitable error handling here
  ENDIF.

  LOOP AT lt_data INTO lwa_data.
*    PERFORM open_group.
    PERFORM bdc_dynpro      USING 'SAPLMGMM' '0060'.
    PERFORM bdc_field       USING 'BDC_CURSOR'
                                  'RMMG1-MTART'.
    PERFORM bdc_field       USING 'BDC_OKCODE'
                                  '=ENTR'.
    PERFORM bdc_field       USING 'RMMG1-MATNR'
                                  lwa_data-matnr.
    PERFORM bdc_field       USING 'RMMG1-MBRSH'
                                  lwa_data-mbrsh.
    PERFORM bdc_field       USING 'RMMG1-MTART'
                                  lwa_data-mtart.
    PERFORM bdc_dynpro      USING 'SAPLMGMM' '0070'.
    PERFORM bdc_field       USING 'BDC_CURSOR'
                                  'MSICHTAUSW-DYTXT(01)'.
    PERFORM bdc_field       USING 'BDC_OKCODE'
                                  '=ENTR'.
    PERFORM bdc_field       USING 'MSICHTAUSW-KZSEL(01)'
                                  'X'.
    PERFORM bdc_dynpro      USING 'SAPLMGMM' '4004'.
    PERFORM bdc_field       USING 'BDC_OKCODE'
                                  '=BU'.
    PERFORM bdc_field       USING 'MAKT-MAKTX'
                                  lwa_data-maktx.
    PERFORM bdc_field       USING 'BDC_CURSOR'
                                  'T006A-MSEHT'.
    PERFORM bdc_field       USING 'MARA-MEINS'
                                  lwa_data-meins.
    PERFORM bdc_field       USING 'MARA-MTPOS_MARA'
                                  '0002'.

    CALL FUNCTION 'BDC_INSERT'
      EXPORTING
        tcode            = 'MM01'
*       POST_LOCAL       = NOVBLOCAL
*       PRINTING         = NOPRINT
*       SIMUBATCH        = ' '
*       CTUPARAMS        = ' '
      TABLES
        dynprotab        = lt_bdcdata
      EXCEPTIONS
        internal_error   = 1
        not_open         = 2
        queue_error      = 3
        tcode_invalid    = 4
        printing_invalid = 5
        posting_invalid  = 6
        OTHERS           = 7.
    IF sy-subrc <> 0.
* Implement suitable error handling here
    ENDIF.

    REFRESH: lt_bdcdata.

  ENDLOOP.

  CALL FUNCTION 'BDC_CLOSE_GROUP'
    EXCEPTIONS
      not_open    = 1
      queue_error = 2
      OTHERS      = 3.
  IF sy-subrc <> 0.
* Implement suitable error handling here
  ENDIF.


FORM bdc_dynpro USING program dynpro.
  CLEAR lwa_bdcdata.
  lwa_bdcdata-program  = program.
  lwa_bdcdata-dynpro   = dynpro.
  lwa_bdcdata-dynbegin = 'X'.
  APPEND  lwa_bdcdata TO lt_bdcdata.
ENDFORM.

*----------------------------------------------------------------------*
*        Insert field                                                  *
*----------------------------------------------------------------------*
FORM bdc_field USING fnam fval.
  CLEAR lwa_bdcdata.
  lwa_bdcdata-fnam = fnam.
  lwa_bdcdata-fval = fval.
  APPEND lwa_bdcdata TO lt_bdcdata.
ENDFORM.