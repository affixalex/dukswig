print("TESTING FROM JS!");
print(typeof(example));
//example.FCONST = 1.2;
print(example.ICONST); try { example.ICONST=12; } catch(err) { print(err); }
print(example.FCONST); try {  example.FCONST=12; } catch(err) { print(err); }
print(example.CCONST); try { example.CCONST=12; } catch(err) { print(err); }
print(example.CCONST2); try { example.CCONST2=12; } catch(err) { print(err);}
print(example.SCONST); try { example.SCONST=12; } catch(err) { print(err); }
print(example.SCONST2); try { example.SCONST2=12; } catch(err) { print(err); }
print(example.EXPR); try { example.EXPR=12;} catch(err) { print(err);}
print(example.iconst); try { example.iconst=12;} catch(err) {print(err);}
print(example.fconst); try { example.fconst=12;} catch(err) {print(err);}

//print(typeof(example.FCONST));
//print(example.FCONST());