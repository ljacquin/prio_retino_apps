Create_partitions_train_valid_test<-function(Prop_train=NULL, Prop_valid=NULL, Vect_classes=NULL)
{
  Table_of_classes<-table(Vect_classes)
  nb_class<-length(unique(Vect_classes))
  List_partitions<-vector(mode = 'list', length = nb_class )
  
  for ( i in 1:nb_class )
  {
    freq_class_i<-as.numeric(Table_of_classes[i])
    nb_train<-floor(Prop_train*freq_class_i)
    nb_valid<-floor(Prop_valid*freq_class_i)
    nb_test<-freq_class_i-(nb_train + nb_valid)
    List_partitions[[i]]<-split( sample(1:freq_class_i), f=c(rep('Train',nb_train), rep('Valid',nb_valid), rep('Test',nb_test)) )
  }
  
  return( List_partitions )
}