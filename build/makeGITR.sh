#!/bin/bash
source ../env.gpufusion.sh

~/cmake/cmake-3.7.0-rc1-Linux-x86_64/bin/cmake -DTHRUST_INCLUDE_DIR=$CUDA_PATH/include \
    -DNETCDF_DIR=$NETCDF \
    -DNETCDF_CXX_ROOT=$NETCDFCXX4 \
    -DLIBCONFIGPP_LIBRARY=$LIBCONFIGDIR/$LIBCONFIGLIB \
    -DMPI_C_LIBRARIES=/cm/shared/apps/mpich/ge/gcc/64/3.2.1/lib \
    -DUSE_CUDA=1 \
    -DUSEMPI=0 \
    -DUSE_MPI=1 \
    -DUSE_BOOST=1 \
    -DUSEIONIZATION=1 \
    -DUSERECOMBINATION=0 \
    -DUSEPERPDIFFUSION=0 \
    -DUSECOULOMBCOLLISIONS=0 \
    -DUSEFRICTION=0 \
    -DUSEANGLESCATTERING=0 \
    -DUSEHEATING=0 \
    -DUSETHERMALFORCE=0 \
    -DUSESURFACEMODEL=0 \
    -DUSESHEATHEFIELD=1 \
    -DBIASED_SURFACE=0 \
    -DUSEPRESHEATHEFIELD=0 \
    -DBFIELD_INTERP=0 \
    -DLC_INTERP=0 \
    -DGENERATE_LC=0 \
    -DEFIELD_INTERP=0 \
    -DPRESHEATH_INTERP=0 \
    -DDENSITY_INTERP=0 \
    -DTEMP_INTERP=0 \
    -DFLOWV_INTERP=0 \
    -DGRADT_INTERP=0 \
    -DODEINT=0 \
    -DFIXEDSEEDS=1 \
    -DPARTICLESEEDS=1 \
    -DPARTICLE_SOURCE_SPACE=0 \
    -DPARTICLE_SOURCE_ENERGY=0 \
    -DPARTICLE_SOURCE_ANGLE=0 \
    -DPARTICLE_SOURCE_FILE=0 \
    -DGEOM_TRACE=0 \
    -DGEOM_HASH=0 \
    -DGEOM_HASH_SHEATH=0 \
    -DPARTICLE_TRACKS=1 \
    -DSPECTROSCOPY=3 \
    -DUSE3DTETGEOM=1 \
    -DUSECYLSYMM=0 \
    -DCHECK_COMPATIBILITY=1 \
    -DFORCE_EVAL=1 \
    -DFLUX_EA=1 \
    -DUSEFIELDALIGNEDVALUES=0 \
    -DUSE_OPENMP=0 \
    -DUSE_SORT=0 \
    ..
    #-DMANUAL_FLAGS={$USECUDA_ $USEMPI_ $USEBOOST_ $USEIONIZATION_} \
    #-DMANUAL_FLAGS="-DUSEIONIZATION=1" \
#~/cmake/cmake-3.7.0-rc1-Linux-x86_64/bin/cmake -DCMAKE_BUILD_TYPE=Debug -DTHRUST_INCLUDE_DIR=$CUDA_PATH/include -DNETCDF_DIR=$NETCDF -DNETCDF_CXX_ROOT=$NETCDFCXX4 -DLIBCONFIGPP_LIBRARY=$LIBCONFIGDIR/$LIBCONFIGLIB  ..
