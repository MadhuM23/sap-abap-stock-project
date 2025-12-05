REPORT zadd_stock_mov.

PARAMETERS:
  p_mat  TYPE zstock_movement-mat_id   OBLIGATORY,
  p_type TYPE zstock_movement-move_type OBLIGATORY,
  p_qty  TYPE zstock_movement-quantity    OBLIGATORY.

DATA: wa_mov      TYPE zstock_movement,
      lv_count    TYPE i,
      lv_num_str  TYPE string,
      lv_new_doc  TYPE zstock_movement-doc_no,
      lv_mat      TYPE zmaterial_master-mat_id,
      lv_curr_stk TYPE zstock_movement-current_stock.

" Check if material exists
SELECT SINGLE mat_id
  FROM zmaterial_master
  INTO @lv_mat
  WHERE mat_id = @p_mat.

IF sy-subrc <> 0.
  MESSAGE 'Material does not exist. Please create it first.' TYPE 'E'.
ENDIF.

" Validate movement type
IF p_type <> 'IN' AND p_type <> 'OUT'.
  MESSAGE 'Movement type must be IN or OUT' TYPE 'E'.
ENDIF.

" Validate quantity
IF p_qty <= 0.
  MESSAGE 'Quantity must be greater than zero' TYPE 'E'.
ENDIF.

" Calculate current stock
SELECT SUM( quantity )
  INTO @lv_curr_stk
  FROM zstock_movement
  WHERE mat_id = @p_mat
    AND move_type = 'IN'.

SELECT SUM( quantity )
  INTO @DATA(lv_out_stk)
  FROM zstock_movement
  WHERE mat_id = @p_mat
    AND move_type = 'OUT'.

lv_curr_stk = lv_curr_stk - lv_out_stk.

IF p_type = 'IN'.
  lv_curr_stk = lv_curr_stk + p_qty.
ELSEIF p_type = 'OUT'.
  IF p_qty > lv_curr_stk.
    MESSAGE 'Not enough stock available for this OUT movement' TYPE 'E'.
  ENDIF.
  lv_curr_stk = lv_curr_stk - p_qty.
ENDIF.

" Generate Document Number
SELECT COUNT(*)
  FROM zstock_movement
  INTO @lv_count.

lv_count = lv_count + 1.

IF lv_count < 10.
  lv_num_str = '00' && lv_count.
ELSEIF lv_count < 100.
  lv_num_str = '0'  && lv_count.
ELSE.
  lv_num_str = |{ lv_count }|.
ENDIF.

lv_new_doc = 'DOC' && lv_num_str.

" Fill structure
wa_mov-doc_no        = lv_new_doc.
wa_mov-mat_id        = p_mat.
wa_mov-move_type     = p_type.
wa_mov-quantity      = p_qty.
wa_mov-current_stock = lv_curr_stk.
wa_mov-move_date     = sy-datum.
wa_mov-created_by    = sy-uname.
wa_mov-created_on    = sy-datum.

INSERT zstock_movement FROM wa_mov.

IF sy-subrc = 0.
  WRITE: / 'Stock Movement Posted Successfully',
         / 'Document Number: ', lv_new_doc,
         / 'Material ID:     ', p_mat,
         / 'Movement Type:   ', p_type,
         / 'Quantity:        ', p_qty,
         / 'Current Stock:   ', lv_curr_stk.
ELSE.
  WRITE: / 'Insert Failed'.
ENDIF.