*&---------------------------------------------------------------------*
*& Report ZPRG_UPLOAD_MAT_DATA_04
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zprg_upload_mat_data1_04.

PARAMETERS: p_file TYPE localfile.

DATA: lv_file TYPE string.

TYPES: BEGIN OF lty_data,
         matnr  TYPE matnr,
         mbrsh  TYPE mbrsh,
         mtart  TYPE mtart,
         maktx  TYPE maktx,
         meins  TYPE meins,
         zzsyst TYPE zdesys04,
         zzmtyp TYPE zdemtype04,
       END OF lty_data.

DATA: lt_data  TYPE TABLE OF lty_data,
      lwa_data TYPE lty_data.

DATA: lwa_headdata    TYPE bapimathead,
      lwa_clientdata  TYPE bapi_mara,
      lwa_clientdatax TYPE bapi_marax.

DATA: lt_desc  TYPE TABLE OF bapi_makt,
      lwa_desc TYPE bapi_makt.

DATA: lwa_return TYPE bapiret2,
      lt_return  TYPE TABLE OF bapiret2.

DATA: lwa_te_mara  TYPE bapi_te_mara,
      lwa_te_marax TYPE bapi_te_marax.

DATA: lt_extensionin  TYPE TABLE OF bapiparex,
      lwa_extensionin TYPE bapiparex.

DATA: lt_extensioninx  TYPE TABLE OF bapiparexx,
      lwa_extensioninx TYPE bapiparexx.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_file.
  CALL FUNCTION 'F4_FILENAME'
    EXPORTING
      program_name  = syst-cprog
      dynpro_number = syst-dynnr
*     FIELD_NAME    = ' '
    IMPORTING
      file_name     = p_file.

START-OF-SELECTION.

  lv_file = p_file. " explicit type casting

  CALL FUNCTION 'GUI_UPLOAD'
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

  LOOP AT lt_data INTO lwa_data.
    lwa_headdata-material = lwa_data-matnr.
    lwa_headdata-ind_sector = lwa_data-mbrsh.
    lwa_headdata-matl_type = lwa_data-mtart.
    lwa_headdata-basic_view = 'X'.

    lwa_clientdata-base_uom = lwa_data-meins.
*update structure for client data
    lwa_clientdatax-base_uom = 'X'.

    lwa_desc-langu = sy-langu.
    lwa_desc-matl_desc = lwa_data-maktx.
    APPEND lwa_desc TO lt_desc.
    CLEAR: lwa_desc.
* adding data of custom fields
    lwa_te_mara-material = lwa_data-matnr.
    lwa_te_mara-zzsyst = lwa_data-zzsyst.
    lwa_te_mara-zzmtyp = lwa_data-zzmtyp.
* update structure for custom fields
    lwa_te_marax-material = lwa_data-matnr.
    lwa_te_marax-zzsyst = 'X'.
    lwa_te_marax-zzmtyp = 'X'.

    lwa_extensionin-structure = 'BAPI_TE_MARA'.
    lwa_extensionin-valuepart1 = lwa_te_mara.
    APPEND lwa_extensionin TO lt_extensionin.
    CLEAR: lwa_extensionin.

    lwa_extensioninx-structure = 'BAPI_TE_MARAX'.
    lwa_extensioninx-valuepart1 = lwa_te_marax.
    APPEND lwa_extensioninx TO lt_extensioninx.
    CLEAR: lwa_extensioninx.

    CALL FUNCTION 'BAPI_MATERIAL_SAVEDATA'
      EXPORTING
        headdata            = lwa_headdata
        clientdata          = lwa_clientdata
        clientdatax         = lwa_clientdatax
*       PLANTDATA           =
*       PLANTDATAX          =
*       FORECASTPARAMETERS  =
*       FORECASTPARAMETERSX =
*       PLANNINGDATA        =
*       PLANNINGDATAX       =
*       STORAGELOCATIONDATA =
*       STORAGELOCATIONDATAX        =
*       VALUATIONDATA       =
*       VALUATIONDATAX      =
*       WAREHOUSENUMBERDATA =
*       WAREHOUSENUMBERDATAX        =
*       SALESDATA           =
*       SALESDATAX          =
*       STORAGETYPEDATA     =
*       STORAGETYPEDATAX    =
*       FLAG_ONLINE         = ' '
*       FLAG_CAD_CALL       = ' '
*       NO_DEQUEUE          = ' '
*       NO_ROLLBACK_WORK    = ' '
*       CLIENTDATACWM       =
*       CLIENTDATACWMX      =
*       VALUATIONDATACWM    =
*       VALUATIONDATACWMX   =
*       MATPLSTADATA        =
*       MATPLSTADATAX       =
*       MARC_APS_EXTDATA    =
*       MARC_APS_EXTDATAX   =
      IMPORTING
        return              = lwa_return
      TABLES
        materialdescription = lt_desc
*       UNITSOFMEASURE      =
*       UNITSOFMEASUREX     =
*       INTERNATIONALARTNOS =
*       MATERIALLONGTEXT    =
*       TAXCLASSIFICATIONS  =
*       RETURNMESSAGES      =
*       PRTDATA             =
*       PRTDATAX            =
        extensionin         = lt_extensionin
        extensioninx        = lt_extensioninx.

    APPEND lwa_return TO lt_return.
    CLEAR: lwa_return.

    CLEAR: lwa_headdata, lwa_clientdata, lwa_clientdatax, lwa_te_mara, lwa_te_marax.

    REFRESH: lt_desc, lt_extensionin, lt_extensioninx.

  ENDLOOP.

  LOOP AT lt_return INTO lwa_return.

    WRITE: lwa_return-message.

  ENDLOOP.