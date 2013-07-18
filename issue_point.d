C:\Users\kazuki\Dropbox\dgnsstec\gnss-sdrlib\src\sdracq.d:
   35          do{
   36              synchronized(hreadmtx)
   37:                 now = sdrstat.buffloccnt;
   38          }while(now < needBuffCnt);
   39  
   ..
   42      }else{
   43          synchronized(hreadmtx)
   44:             buffloc = sdrini.fendbuffsize * sdrstat.buffloccnt - sdr.acq.intg * sdr.nsamp;
   45      }
   46  
   ..
   51          do {
   52              synchronized(hreadmtx)
   53:                 bufflocnow = sdrini.fendbuffsize * sdrstat.buffloccnt - sdr.nsamp;
   54          } while (bufflocnow < buffloc);
   55  

C:\Users\kazuki\Dropbox\dgnsstec\gnss-sdrlib\src\sdrrcv.d:
  311      //WaitForSingleObject(hbuffmtx,INFINITE);
  312      synchronized(hbuffmtx){
  313:         if(sdrini.fp1.isOpen) nread1=fread(&sdrstat.buff1[(sdrstat.buffloccnt%MEMBUFLEN)*sdrini.dtype[0]*FILE_BUFFSIZE],1,sdrini.dtype[0]*FILE_BUFFSIZE,sdrini.fp1.getFP);
  314:         if(sdrini.fp2.isOpen) nread2=fread(&sdrstat.buff2[(sdrstat.buffloccnt%MEMBUFLEN)*sdrini.dtype[1]*FILE_BUFFSIZE],1,sdrini.dtype[1]*FILE_BUFFSIZE,sdrini.fp2.getFP);
  315      }
  316      //ReleaseMutex(hbuffmtx);
  ...
  323      //WaitForSingleObject(hreadmtx,INFINITE);
  324      synchronized(hreadmtx)
  325:         sdrstat.buffloccnt++;
  326      //ReleaseMutex(hreadmtx);
  327  }

C:\Users\kazuki\Dropbox\dgnsstec\gnss-sdrlib\src\sdrtrk.d:
   28      ulong bufflocnow;
   29      synchronized(hreadmtx)
   30:         bufflocnow = sdrini.fendbuffsize*sdrstat.buffloccnt-sdr.nsamp; 
   31      
   32      if (bufflocnow > buffloc) {
