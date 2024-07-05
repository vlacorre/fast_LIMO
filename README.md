# Fast LIMO
<details>
    <summary>Table of Contents</summary>
    <ol>
        <li>
        <a href="#disclaimer">Disclaimer</a>
        </li>
        <li><a href="#dependencies">Dependencies</a>
        </li>
        <li>
        <a href="#quick-start">Quick Start</a>
        </li>
        <li>
        <a href="#approach">Approach</a>
        </li>
        <li>
        <a href="#configuration">Configuration</a>
        </li>
        <li>
        <a href="#references">References</a>
        </li>
    </ol>
</details>

<br>

A real-time, tightly coupled LiDAR-Inertial SLAM algorithm developed on top of [IKFoM](https://github.com/hku-mars/IKFoM) and [ikd-Tree](https://github.com/hku-mars/ikd-Tree) _C++_ libraries. This project's implementation is based on the existing algorithms [FASTLIO2](https://github.com/hku-mars/FAST_LIO), [LIMO-Velo](https://github.com/Huguet57/LIMO-Velo) and [DLIO](https://github.com/vectr-ucla/direct_lidar_inertial_odometry).

`Fast-LIMO` has been developed as a thread-safe _C++_ library with [Eigen3](https://eigen.tuxfamily.org/index.php?title=Main_Page) and [PCL](https://pointclouds.org/) as its only dependencies. This way, it can be used outside the ROS framework without any changes, making it more portable. This project acts as a ROS wrapper of the self-developed [fast_limo](include/fast_limo/)'s library.

`Fast-LIMO` stands for a multithreaded version of the approach _Localize Intensively Map Offline (LIMO)_ stated in [LIMO-Velo](https://github.com/Huguet57/LIMO-Velo) 's algorithm developed by [Huget57](https://github.com/Huguet57). 

<p align="center">
  <img src="doc/cat15.gif" alt="CAT15X's performance"  width="800"/>
  <small>Formula Student race car <a href="https://youtu.be/mk9U0lRWr-0?si=j4mM6e5dzihfCLJM">CAT15X</a>. Velocity in straights (~12m/s) and really tight turns (~100deg/s) </small>
</p>
<br/>

<p align="center">
  <img src="doc/kitti_0071.gif" alt="KITTI 0071 performance"  width="800"/>
  <small><a href="https://www.cvlibs.net/datasets/kitti/index.php">KITTI</a> dataset. Dynamic objects being added to the map. Still robust enough. </small>
</p>
<br/>

<p align="center">
  <img src="doc/xaloc.gif" alt="XALOC's performance"  width="800"/>
  <small>Formula Student race car <a href="https://youtu.be/ly_ax8w-T7E?si=sDFiMFtRN5jRwWKC">XALOC</a>. High velocity in straights (~15m/s) and tight turns (~80deg/s).</small>
</p>

## Disclaimer
If you plan to use `Fast-LIMO` please make sure to give some love to [LIMO-Velo](https://github.com/Huguet57/LIMO-Velo), [FASTLIO2](https://github.com/hku-mars/FAST_LIO) and [DLIO](https://github.com/vectr-ucla/direct_lidar_inertial_odometry) projects, which greatly influenced this work.

## Dependencies
<details open>
    <summary>Fast-LIMO C++14 library:</summary>
    <ol>
        <li>
        <a href="https://eigen.tuxfamily.org/index.php?title=Main_Page">Eigen3</a>
        </li>
        <li>
        <a href="https://pointclouds.org/">PCL (1.8)</a>
        </li>
    </ol>
</details>

<details>
    <summary>ROS (Noetic) wrapper:</summary>
    <ol>
        <li>
        <a href="./include/fast_limo/">fast_limo</a>
        </li>
        <li><a href="http://wiki.ros.org/pcl_ros">pcl_ros</a>
        </li>
        <li>
        <a href="http://wiki.ros.org/sensor_msgs">sensor_msgs</a>
        </li>
        <li>
        <a href="http://wiki.ros.org/geometry_msgs">geometry_msgs</a>
        </li>
        <li>
        <a href="https://wiki.ros.org/tf2">tf2</a>
        </li>
    </ol>
</details>


## Quick Start
### 0. Cloning the repo
```sh
git clone https://github.com/fetty31/fast_LIMO
```

### 1. Building fast LIMO
Use default `catkin_make` or `catkin build` to build the code. By default it will compile under the `CMAKE_BUILD_TYPE="Release"` flag.

### 2. Running fast LIMO
```sh
roslaunch fast_limo fast_limo.launch
```

Afterwards, you should be seeing this output _(if `verbose` param is set to true)_:

<div align="center">
<a> <img src="doc/verbose.png" alt="Logo" width="555"> </a>
</div>
<br />

You can also run `Fast-LIMO` together with an rviz instance with:
```sh
roslaunch fast_limo fast_limo.launch rviz:=true
```

### 4. Quickly check its performance
[IN THIS FOLDER](https://www.dropbox.com/scl/fi/60u6xq0daav9enecluroh/cat15_trackdrive.bag?rlkey=jfjba58h8hohfi8b7kpi8zsvx&st=jck682n6&dl=0) you can find the rosbag file (___850.41 MB___) of [this CAT15X trackdrive](https://youtu.be/mk9U0lRWr-0?si=j4mM6e5dzihfCLJM). Download it and try it out!
```sh
roslaunch fast_limo cat.launch rviz:=true
```

_Note that this algorithm's precision greatly depends on the pointcloud & IMU timestamps, so remember to run the rosbag with __use_sim_time=true__ and __--clock__ flag._

## Approach
If you are interested in truly understanding the working principle of this SLAM algorithm, please read the [FASTLIO paper](https://doi.org/10.48550/arXiv.2010.08196). _This project is merely an alternative implementation of this outstanding work, still relying upon [IKFoM](include/IKFoM/) and [ikd-Tree](include/ikd-Tree/) open-source projects._

This project implements the same concept as [LIMO-Velo](https://github.com/Huguet57/LIMO-Velo) but without any accumulation procedure. Instead, `Fast-LIMO` operates with two concurrent threads. One thread handles the propagation of newly received IMU measurements through the iKFoM (prediction stage), while the other thread uses these propagated states to deskew the received point cloud, match the deskewed scan to the map, and update the iKFoM (measurement stage) by minimizing point-to-plane distances.

`Fast-LIMO` supports the standard IMU-LiDAR configuration, where the IMU provides new measurements at a rate of 100-500 Hz and the LiDAR sends a new point cloud approximately every 10 Hz. __However, optimal performance can be achieved with a modified LiDAR driver that sends each scan packet as soon as it is ready, instead of waiting for the LiDAR to complete a full rotation.__

## Configuration
Here, the configuration file for `Fast-LIMO` is explained. _Note that some parameters relate to the __sensor type__ and __extrinsics__. The remaining parameters generally do not require modification for standard use, as they are associated with computational load limits or precision thresholds._

| Parameter             | Units | Summary                           |
| --------------        | ----- | --------------------------------- |
| num_threads           | -  | OpenMP threads (will be equal to $(nproc) if it is set higher). |
| sensor_type           | -  | LiDAR type (0: OUSTER \ 1: VELODYNE \ 2: HESAI \ 3: LIVOX). |
| debug                 | -  | Save useful intermediate pcl for visualization purposes (pc2match, deskewed...).  |
| verbose               | -  | Print debugging board with performance stats. |
| estimate_extrinsics   | -  | Enable continuous estimation of LiDAR-IMU extrinsics as in FASTLIOv2. |
| time_offset           | -  | Whether to take into account a possible sync offset between IMU and LiDAR (set to true if they are not properly synchronized).  |
| end_of_sweep          | -  | Whether the sweep reference time is w.r.t. the start or the end of the scan (only applies to VELODYNE/OUSTER sensors, which have relative timestamp). |
| calibration/gravity_align | - | Estimate gravity vector while the robot is at stand still. |
| calibration/accel         | - | Estimate linear accel. bias while the robot is at stand still. |
| calibration/gyro          | - | Estimate angular velocity while the robot is at stand still. |
| calibration/time          | s | Time at the beggining to estimate the quantities above. The robot MUST be at stand still. If all three flags above are set to false, no estimate will be done.  |
| extrinsics/imu            | SI | IMU pose with respect to base_link coordinate frame. |
| extrinsics/lidar          | SI | LiDAR pose with respect to base_link coord. frame.  |
| intrinsics                | SI | IMU lin. + gyro. biases.  |
| filters/cropBox           | m | Prismatic crop. Useful for removing LiDAR points that fall into the robot itself. Should be a 3D rectangle envolving the robot. |
| filters/voxelGrid         | m | Voxel Grid filter. Pointcloud downsampling strategy. |
| filters/minDistance       | m | Could be interpreted as a sphere crop. Removes all points closer than its value. Useful for avoiding having too many ground points. |
| filters/rateSampling      | - | Quick downsampling method. Only takes into account 1 in every _value_ points. _Useful for reducing the computational load._ |
| iKFoM/MAX_NUM_ITERS       | - | The Extended Kalman Filter will do _MAX_NUM_ITERS_+1 iterations. _Useful for reducing the computational load._ |
| iKFoM/MAX_NUM_MATCHES     | - | Max. number of matches to account for when computing the Jacobians. _Useful for reducing the computational load._|
| iKFoM/MAX_NUM_PC2MATCH    | - | Max. number of points to consider when matching the current scan with the map. _Useful for reducing the computational load._ |
| iKFoM/Mapping/NUM_MATCH_POINTS  | - | Number of points that constitute a match. |
| iKFoM/Mapping/MAX_DIST_PLANE    | m | Max. distance between all points of a match. |
| iKFoM/Mapping/PLANES_THRESHOLD  | m | Threshold to consider if a match point is part of a plane. |
| iKFoM/Mapping/LocalMapping      | - | Whether to keep a fixed size map (_moving with the robot_) or a limitless map. Useful for limiting the memory used (_in long runs_). |
| iKFoM/iKDTree/balance           | - | Incremental KD Tree balancing param. |
| iKFoM/iKDTree/delete            | - | Incremental KD Tree deletion param. |
| iKFoM/iKDTree/voxel             | - | Incremental KD Tree downsampling param. _Currently not used_ |
| iKFoM/iKDTree/bb_size           | m | Local Map's bounding box dimension (actually a cube). _When LocalMapping is active, the local map won't include points outside this cube. Note that the local map is always defined relative to the robot's current position._ |
| iKFoM/iKDTree/bb_range          | m | Local Map's bounding box moving range (if the robot is closer than _bb_range_ to any local map's edge, the map will "move"). |
| iKFoM/covariance                | m^2 | Covariance of IMU measurements. |

## References
This project relies upon [HKU-Mars](https://github.com/hku-mars)' open-source _C++_ libraries:
- Iterative Kalman Filters on Manifolds ([IKFoM](include/IKFoM/)) 
- Incremental KD-Tree ([ikd-Tree](include/ikd-Tree/)) 