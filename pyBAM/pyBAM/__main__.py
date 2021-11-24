#!/usr/bin/env python3
#-----------------------------------------------------------------------------#
#           Group on Data Assimilation Development - GDAD/CPTEC/INPE          #
#-----------------------------------------------------------------------------#
#BOP
#
# !SCRIPT: gsiDiag.py
#
# !DESCRIPTION: Class to read and plot GSI diagnostics files.
#
# !CALLING SEQUENCE:
#
# !REVISION HISTORY: 
# 09 out 2017 - J. G. de Mattos - Initial Version
#
# !REMARKS:
#   Work only with conventional diganostics files
#
#EOP
#-----------------------------------------------------------------------------#
#BOC

"""
This module defines the majority of pyBAM functions, including all plot types
"""
from pythonBAM import pythonbam as pBAM
import numpy as np
import xarray as xr
import matplotlib as mpl
import matplotlib.pyplot as plt
from tqdm import tqdm
#
# 
import cartopy.crs as ccrs
from cartopy.mpl.ticker import LongitudeFormatter, LatitudeFormatter

def help():
    print('Esta é uma ajudada')

def inter_from_256(x):
    return np.interp(x=x,xp=[0,255],fp=[0,1])

def GrADSColors():
    
   rgb = np.array(
         [[160,   0, 200],
          [110,   0, 220],
          [ 30,  60, 255],
          [  0, 160, 255],
          [  0, 200, 200],
          [  0, 210, 140],
          [  0, 220,   0],
          [160, 230,  50],
          [230, 220,  50],
          [230, 175,  45],
          [240, 130,  40],
          [250,  60,  60],
          [240,   0, 130]]) / 255

   return mpl.colors.ListedColormap(rgb)


def defineMap():
    fig = plt.figure(figsize=(8, 10))
    
    # Label axes of a Plate Carree projection with a central longitude of -180:
    ax1 = fig.add_subplot(1, 1, 1,
                          projection=ccrs.PlateCarree(central_longitude=-180))
    ax1.set_global()
    ax1.coastlines()
    ax1.set_xticks([0, 60, 120, 180, 240, 300, 360], crs=ccrs.PlateCarree())
    #ax1.xaxis.set_tick_params(labeltop='on')
    ax1.set_yticks([-90, -60, -30, 0, 30, 60, 90], crs=ccrs.PlateCarree())
    #ax1.yaxis.set_tick_params(labelright='on')
    lon_formatter = LongitudeFormatter(zero_direction_label=True)
    lat_formatter = LatitudeFormatter()
    ax1.xaxis.set_major_formatter(lon_formatter)
    ax1.yaxis.set_major_formatter(lat_formatter)

def parseMinMax(rmin,rmax):

    rdif  = (rmax - rmin)/10.0  # appx. 10 intervals
    w2    = np.floor(np.log10(rdif))
    w1    = 10.0**w2
    norml = rdif/w1 #normalized interval

    if norml>=1.0 and norml<=1.5:
        cint=1.0
    elif norml>1.5 and norml<=2.5: 
        cint=2.0
    elif norml>2.5 and norml<=3.5: 
        cint=3.0
    elif norml>3.5 and norml<=7.5: 
        cint=5.0
    else:
        cint=10.0

    cint = cint*w1

    cmin = cint * np.ceil(rmin/cint)  
    cmax = cint * np.floor(rmax/cint) 

#    cmin = cint * math.ceil(rmin/cint + 1.0)  
#    cmax = cint * math.floor(rmax/cint) 
    
#    if cmin < 0:
#        cmin = -1 * cmax 
    return cmin,cmax,cint

def getColorInfo(rmin,rmax):

    #
    # get min, max and int
    #
    cmin,cmax,cint=parseMinMax(rmin,rmax)

    #
    # define GrADS color rainbow
    #

    cmap = plt.cm.jet
#    cmap.set_under('silver')
#    cmap.set_over('dimgray') 

    #
    # define bounds
    #
    bounds = np.arange(cmin,cmax+cint,cint)
    norm = mpl.colors.BoundaryNorm(bounds, cmap.N)
    vmin, vmax = min(bounds), max(bounds)

    return cmap, norm, vmin,vmax

class openBAM(object):
    """
    read a diagnostic file from gsi. Return an array with
    some information.
    """

    def __init__(self, header, binary=None, mode=None, ftype=None, initSpec=None):

        self.header  = header
        #
        # parse open arguments
        #

        # verify binary file name
        if binary is None:
            prefix,htype,mres=header.split(".")
            if (htype == 'dic'):
                print("htype is", htype)
                btype = 'icn'
            elif (htype == 'din'):
                print("htype is", htype)
                btype = 'inz'
            elif (htype == 'dir'):
                print("htype is", htype)
                btype = 'fct'
            elif (htype == 'dun'):
                print("htype is", htype)
                btype = 'unf'
            else:
                print('ERROR: file not open!')
                print('ERROR: unknown file type, abort ...')
                return
            self.binary = prefix+'.'+btype+'.'+mres
        else:
            self.binary = binary

        # verify file type
        if ftype is None:
           self.ftype = btype
        else:
           self.ftype = ftype

        # verify file access
        if mode is None:
            self.mode = 'r'
        else:
            self.mode = mode

        # verify spectral initialization
        if initSpec is None:
            self.initSpec = True
        else:
            self.initSpec = initSpec

        self.FNumber = pBAM.open(self.header, self.binary, self.mode,
                                      self.ftype, self.initSpec)

        if (self.FNumber == -1):
            self.FNumber = None
            print('ERROR: file not open!')
            return

        # get dim info (arrays)
        self.nlon = pBAM.getDim(self.FNumber,'lon')
        if self.nlon > 0:
           self.lons    = pBAM.array1d.copy()
           pBAM.array1d = None

        self.nlat = pBAM.getDim(self.FNumber,'lat')
        if self.nlat > 0:
           self.lats    = pBAM.array1d.copy()
           pBAM.array1d = None

        self.nlevels = pBAM.getVerticalLevels(self.FNumber)
        if self.nlevels > 0:
            self.levels = pBAM.array1d.copy()
            pBAM.array1d = None

        self.nVars = pBAM.getNVars(self.FNumber)
        varNames   = pBAM.getVarNames(self.FNumber, self.nVars)
        self.VarNames   = []
        for name in varNames:
           self.VarNames.append(name.tostring().decode('UTF-8').strip())   


    def close(self):

        """
        Closes a previous openned file. Returns an integer status value.

        Usage: close()
        """

        iret = pBAM.close(self.FNumber)
        self.FNumber  = None # File unit number to be closed
        self.header   = None # BAM header file (din, dic, dir, dun)
        self.binary   = None # BAM binary file (inz, icn, fct, unf)
        self.ftype    = None # type of binary file (inz, icn, fct, unf)
        self.mode     = None # open mode (r-read, w-write)
        self.initSpec = None # Initialize Spectral Transform ? 
        self.nlon     = None # Number of longitudinal points
        self.nlat     = None # Number of latitudinal points
        self.lons     = None # array of londitudes
        self.lats     = None # array of latitudes
        self.VarNames = None  # Name of variables


        return iret


    def getField(self, fieldName, zlevel=None):

        if zlevel is None:
            zlevel = 1

        iret = pBAM.getField(self.FNumber, fieldName, zlevel)
        if (iret == 0):
            da = xr.DataArray(data   = pBAM.array2d.transpose().copy(),
                              name   = fieldName,
                              dims   = ['lat','lon'],
                              coords = {'lat': self.lats[::-1],
                                        'lon': self.lons})
            pBAM.array2d = None

            return da
        else:
            print('Error to get field',fieldName,iret)
            return iret
            
    def getField3D(self, fieldName, zlevels=None):

        if zlevels is None:
           nlevs  = pBAM.getNLevels(self.FNumber, fieldName)
           levels = self.levels
        else:
           nlevs  = len(zlevels)
           levels = self.levels[[z-1 for z in zlevels]]

        print('Will get ',nlevs,'zlevels from ', fieldName)
        print('This operation will take a while ...')
        da = {}
        for k, level in enumerate(tqdm(levels)):
            da[k] = self.getField(fieldName,k+1)
            da[k] = da[k].assign_coords(zlev=level)

        da = xr.concat([da[i] for i in da],dim='zlev')

        return da

    def plotField(self, fieldName, zlevel=None, colorbar=False, **kwargs):

        if zlevel is None:
            zlevel = 1

        if 'levels' not in kwargs:
            kwargs['levels'] = 13

        if 'extend' not in kwargs:
            kwargs['extend'] = 'both'

        if 'cmap' not in kwargs:
            kwargs['cmap'] = GrADSColors()

        if 'cbar_kwargs' not in kwargs:
            kwargs['cbar_kwargs'] = {
                                     "orientation": "horizontal",
                                     "shrink": 0.8,
                                     "aspect": 40,
                                     "pad": 0.1,
                                    }

        field = self.getField(fieldName, zlevel)
        if not np.isscalar(field):
            defineMap()

            img = field.plot(transform=ccrs.PlateCarree(), **kwargs)

        return img

#EOC
#-----------------------------------------------------------------------------#

