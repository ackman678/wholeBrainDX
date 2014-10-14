Author: James B. Ackman  
Date: 2013-07-03 12:16:50  

# wholeBrainDX

Image analysis software for whole brain calcium imaging movies (Ackman et al. 2012-2014;).

Usage instructions at [wholeBrain_workflow.md](wholeBrain_workflow.md)

# Installation

1. Clone wholeBrainDX from GitHub into your *$MATLABHOME* user folder.
2. Add wholeBrainDX to your [matlab path][matlabSearchPath]
3. Install the core dependency toolboxes. Add them your matlab search path or use the `addpath(genpath('$PATH/$MATLABHOME/toolbox'))` syntax at the command prompt when starting up matlab with each toolbox.
4. *Optional:* Install the non-core dependency toolboxes. Same as above, add their folders and subfolders to your matlab path.

# Requirements

## Core dependencies ##

* matlab with the signal processing and image processing toolboxes
* [CalciumDX](https://github.com/ackman678/CalciumDX) This is used mostly just to help with setting up dummy parcellation files for inputs to wholeBrain_batch.m (explained in [wholeBrain_workflow.md](wholeBrain_workflow.md)). Also calls myOpenOMEtiff.m for tiff movie opening.
* [piotrImageVideoProcessingToolbox][piotrToolbox]. Uses gaussSmooth and xcorrn from this toolbox.
* [bfmatlab](http://www.openmicroscopy.org/site/support/bio-formats5/users/matlab/index.html), a matlab toolbox containing the bio-formats java plugin and a `bfopen.m` reader function for opening many different microscopy image/tiff file formats.

## Non-core dependencies ##

* [sigTOOL][sigtool]. Used with the stimulus movies workflow and dealing with motor signals. This program is useful if going to use simultaneously acquired electrophysiology, stimulation data stored in a a data format readable by sigtool, such as CED Spike2 .smr files. This toolbox will read those files and output a .kcl matlab data structure file format.



# License

Copyright (C) 2014 James B. Ackman  
Except where otherwise noted, all code in this program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but without any warranty; without even the implied warranty of merchantability or fitness for a particular purpose. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.



[SyncPushPull]: http://mac.github.com/help.html#faq-sync-push-pull

[matlabSearchPath]: http://www.mathworks.com/help/matlab/matlab_env/what-is-the-matlab-search-path.html

[piotrToolbox]: http://vision.ucsd.edu/~pdollar/toolbox/doc/

[sigtool]: http://sourceforge.net/projects/sigtool/

[dipumToolbox]: http://www.imageprocessingplace.com/DIPUM_Toolbox_2/DIPUM_Toolbox_2.htm
