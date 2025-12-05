REPORT zstock_classical_colored.

TYPES: BEGIN OF ty_stock,
         mat_id        TYPE zmaterial_master-mat_id,
         mat_desc      TYPE zmaterial_master-mat_desc,
         current_stock TYPE i,
       END OF ty_stock.

DATA: it_stock TYPE TABLE OF ty_stock,
      wa_stock TYPE ty_stock.

DATA: it_materials TYPE TABLE OF zmaterial_master,
      wa_mat       TYPE zmaterial_master.

DATA: it_movements TYPE TABLE OF zstock_movement,
      wa_mov       TYPE zstock_movement.

DATA: lv_in  TYPE i,
      lv_out TYPE i.

" Fetch all materials
SELECT * FROM zmaterial_master INTO TABLE it_materials.

IF it_materials IS INITIAL.
  WRITE: / 'No materials found in master table.'.
  EXIT.
ENDIF.

" Fetch all stock movements
SELECT * FROM zstock_movement INTO TABLE it_movements.

" Calculate current stock for each material
LOOP AT it_materials INTO wa_mat.

  lv_in = 0.
  lv_out = 0.

  LOOP AT it_movements INTO wa_mov WHERE mat_id = wa_mat-mat_id.
    IF wa_mov-move_type = 'IN'.
      lv_in = lv_in + wa_mov-quantity.
    ELSEIF wa_mov-move_type = 'OUT'.
      lv_out = lv_out + wa_mov-quantity.
    ENDIF.
  ENDLOOP.

  CLEAR wa_stock.
  wa_stock-mat_id = wa_mat-mat_id.
  wa_stock-mat_desc = wa_mat-mat_desc.
  wa_stock-current_stock = lv_in - lv_out.

  APPEND wa_stock TO it_stock.

ENDLOOP.


WRITE: / 'Material ID' COLOR 4, 20 'Description' COLOR 4, 50 'Current Stock' COLOR 4.
WRITE: / '-----------------------------------------------------------------------------'.

LOOP AT it_stock INTO wa_stock.

  " Highlight low stock in red
  IF wa_stock-current_stock <= 10.
    WRITE: / wa_stock-mat_id COLOR 6,
             20 wa_stock-mat_desc COLOR 6,
             50 wa_stock-current_stock COLOR 6.
  ELSE.
    WRITE: / wa_stock-mat_id COLOR 1,
             20 wa_stock-mat_desc COLOR 1,
             50 wa_stock-current_stock COLOR 1.
  ENDIF.

ENDLOOP.
