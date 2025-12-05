REPORT zstock_interactive.

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

START-OF-SELECTION.

  " Get all materials and stock movements
  SELECT * FROM zmaterial_master INTO TABLE it_mat.
  SELECT * FROM zstock_movement INTO TABLE it_mov.

  " Calculate current stock for each material
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

    wa_stock-mat_id        = wa_mat-mat_id.
    wa_stock-mat_desc      = wa_mat-mat_desc.
    wa_stock-current_stock = lv_in - lv_out.

    APPEND wa_stock TO it_stock.

  ENDLOOP.

START-OF-SELECTION.

  " Header for main list
  WRITE: / 'Mat ID' COLOR 2, 20 'Description' COLOR 2, 50 'Current Stock' COLOR 2.
  ULINE.

  " Display all materials with stock
  LOOP AT it_stock INTO wa_stock.
    WRITE: / wa_stock-mat_id COLOR 7,
             20 wa_stock-mat_desc COLOR 1,
             50 wa_stock-current_stock COLOR 1.

    " Save material ID for click event
    HIDE wa_stock-mat_id.
  ENDLOOP.

AT LINE-SELECTION.

  " valid row is selected
  IF wa_stock-mat_id IS INITIAL.
    MESSAGE 'Invalid click' TYPE 'I'.
    EXIT.
  ENDIF.

  PERFORM show_details USING wa_stock-mat_id.

FORM show_details USING p_matid.

  DATA: it_moves TYPE TABLE OF zstock_movement,
        wa_move  TYPE zstock_movement.

  " Get stock movements for selected material
  SELECT * FROM zstock_movement INTO TABLE it_moves
    WHERE mat_id = p_matid.

  NEW-PAGE.

  WRITE: / 'Stock Movements for Material:', p_matid.
  ULINE.

  IF it_moves IS INITIAL.
    WRITE: / 'No stock movement records found.'.
    EXIT.
  ENDIF.

  WRITE: / 'Type' COLOR 2, 20 'Quantity' COLOR 2, 40 'Created On' COLOR 2.
  ULINE.

  LOOP AT it_moves INTO wa_move.
    WRITE: / wa_move-move_type COLOR 3,
             20 wa_move-quantity COLOR 4,
             40 wa_move-created_on COLOR 1.
  ENDLOOP.

ENDFORM.