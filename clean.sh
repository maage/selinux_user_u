sed '
/^#======/d;
/^#\!\!\!\! This avc is allowed in the current policy/,+1d;
/^$/d;
'
