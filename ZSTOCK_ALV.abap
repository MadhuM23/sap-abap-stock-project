REPORT zstock_alv.

TYPE-POOLS: slis.

TYPES: BEGIN OF ty_stock,
         mat_id        TYPE zmaterial_master-mat_id,
         mat_desc      TYPE zmaterial_master-mat_desc,
         current_stock TYPE i,
       END OF ty_stock.

DATA: it_stock TYPE TABLE OF ty_stock,
      wa_stock TYPE ty_stock,
      it_mat   TYPE TABLE OF zmaterial_master,
      wa_mat   TYPE zmaterial_master,
      it_mov   TYPE TABLE OF zstock_movement,
      wa_mov   TYPE zstock_movement.

DATA: lv_in  TYPE i,
      lv_out TYPE i.

DATA: it_fcat TYPE slis_t_fieldcat_alv,
      wa_fcat TYPE slis_fieldcat_alv,
      gs_layout TYPE slis_layout_alv.


START-OF-SELECTION.

  SELECT * FROM zmaterial_master INTO TABLE it_mat.
  SELECT * FROM zstock_movement INTO TABLE it_mov.

  " Calculate stock
  LOOP AT it_mat INTO wa_mat.

    lv_in  = 0.
    lv_out = 0.

    LOOP AT it_mov INTO wa_mov WHERE mat_id = wa_mat-mat_id.
      IF wa_mov-move_type = 'IN'.
        lv_in = lv_in + wa_mov-quantity.
      ELSEIF wa_mov-move_type = 'OUT'.
        lv_out = lv_out + wa_mov-quantity.
      ENDIF.
    ENDLOOP.

    wa_stock-mat_id = wa_mat-mat_id.
    wa_stock-mat_desc = wa_mat-mat_desc.
    wa_stock-current_stock = lv_in - lv_out.

    APPEND wa_stock TO it_stock.

  ENDLOOP.


"Field catalog for main ALV

CLEAR it_fcat.

wa_fcat-fieldname = 'MAT_ID'.
wa_fcat-seltext_m = 'Material ID'.
wa_fcat-hotspot   = 'X'. " Clickable
APPEND wa_fcat TO it_fcat.

wa_fcat-fieldname = 'MAT_DESC'.
wa_fcat-seltext_m = 'Description'.
APPEND wa_fcat TO it_fcat.

wa_fcat-fieldname = 'CURRENT_STOCK'.
wa_fcat-seltext_m = 'Current Stock'.
APPEND wa_fcat TO it_fcat.


" Display ALV with PF-STATUS callback for custom button

CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
  EXPORTING
    i_callback_program       = sy-repid
    i_callback_pf_status_set = 'SET_STATUS'
    i_callback_user_command  = 'ON_CLICK'
    it_fieldcat              = it_fcat
    is_layout                = gs_layout
  TABLES
    t_outtab                 = it_stock.

" PF-STATUS: Set toolbar button

FORM set_status USING rt_extab TYPE slis_t_extab.
  " PF-STATUS must be created in SE41 with a button Fcode MYBTN
  SET PF-STATUS 'ZBTN'.
ENDFORM.


"Handle click on ALV or button

FORM on_click USING r_ucomm LIKE sy-ucomm
                     rs_selfield TYPE slis_selfield.

  " Custom button click
  IF r_ucomm = 'MYBTN'.
    MESSAGE 'You clicked custom button!' TYPE 'I'.
    EXIT.
  ENDIF.

  " Hotspot click on Material ID
  READ TABLE it_stock INTO wa_stock INDEX rs_selfield-tabindex.
  IF sy-subrc <> 0.
    MESSAGE 'Click on a valid line' TYPE 'I'.
    EXIT.
  ENDIF.

  " Fetch movements for clicked material
  DATA: lv_mat TYPE zstock_movement-mat_id,
        it_moves TYPE TABLE OF zstock_movement,
        wa_move TYPE zstock_movement,
        it_fcat2 TYPE slis_t_fieldcat_alv,
        wa_fcat2 TYPE slis_fieldcat_alv.

  lv_mat = wa_stock-mat_id.

  SELECT * FROM zstock_movement INTO TABLE it_moves WHERE mat_id = lv_mat.

  IF it_moves IS INITIAL.
    MESSAGE 'No movements found.' TYPE 'I'.
    EXIT.
  ENDIF.

  " Field catalog for movement ALV
  CLEAR it_fcat2.

  wa_fcat2-fieldname = 'MOVE_TYPE'.
  wa_fcat2-seltext_m = 'Type'.
  APPEND wa_fcat2 TO it_fcat2.

  wa_fcat2-fieldname = 'QUANTITY'.
  wa_fcat2-seltext_m = 'Qty'.
  APPEND wa_fcat2 TO it_fcat2.

  wa_fcat2-fieldname = 'CREATED_ON'.
  wa_fcat2-seltext_m = 'Date'.
  APPEND wa_fcat2 TO it_fcat2.

  " Show movement ALV
  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
    EXPORTING
      i_callback_program = sy-repid
      it_fieldcat        = it_fcat2
      i_screen_start_column = 5
      i_screen_start_line   = 5
    TABLES
      t_outtab = it_moves.

ENDFORM.