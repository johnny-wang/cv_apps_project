
Smart Phone Real-Time Augmented Reality Based In-car Navigation System
======================================================================

Team
-------
Yuhan Long

Joonwhee Park

Johnny Wang

####Professor
Simon Lucey

####TA
Chen-Hsuan Lin

Summary
=========

In this project, we will build an augmented reality iOS navigation application (App) for drivers. When people use off-the-shelf applications for navigation, such as Google Maps, it is often difficult to match the road names in real-life against the phone display and understand the navigation directions. Such confusion occurs frequently at intersections as well as highway ramps. The idea of our App is to use the camera of the iOS device to display the scene in real-time on the screen while marking the road names for each branch/ramp of the road. This way, the driver can receive intuitive visual feedback of road information.

Background
===========
To implement this project, several computer vision technologies will be involved.

1.  Automated homography estimation
Our goal is to create a natural projection of the road name when people are using this device. **Figure 1** is a screenshot from Google Street View, which is a still-image of a location. We want to achieve such effect in real-time. This means lane detection and inverse perspective mapping technologies are required.
![Street View](/images/street_view.png)
**Figure 1**: Ideal homography projection result on the map (the "Forbes Ave.").


2.   Image pixel-based segmentation/classification
When the car drives to an intersection, it should detect all the side road/ramp and mark them correctly. **Figure 2** shows a complex intersection. It has four different directions that the driver can drive to. In our App, we want to mark them all correctly. To achieve such function, the software should first classify the part of the road surface in the image. Then the software should analyze the geometric relationship between different parts of road and mark them accordingly.
![Complex Intersection](/images/complex_intersection.png)
**Figure 2**: A complex intersection.


3.  Other technologies
We will use camera API on iOS device to take real-time video data. We will use GIS API to get the road name. We will explore Objective-C solutions to turn text into image for road name projection.

Challenges
==========
As described in the previous section, there are several challenging elements of this project. 

1.  We need to estimate homography autonomously. This means we need to estimate the plane of the road autonomously. When people change their mounting of the device, the estimated plane is going to be changed. We need autonomous plane estimation solution in our software. 

2.  We are doing road segmentation and there will be occlusion in the image. Cars on the road, shades, signal lights, and road signs will add disturbance into the classification.

3.  The team is not adept with Objective-C programming and iOS programming API. Becoming proficient enough to complete these tasks will take time.

Goals & Deliverables
====================
We have three tiers of goals in this project.

   **Tier 1** Functional software achieving off-line augmented reality road marking with a set of collected images. The road name is prescribed in the App. 

   **Tier 2** Functional software achieving real-time augmented reality road marking on select road. e.g. the App works for Forbes avenue from CMU to University of Pittsburgh.

   **Tier 3** Functional software achieving real-time augmented reality road marking for all roads that are listed in the GIS API.

Work Breakdown
==============
Since this is a project with considerable technical difficulties and development work, we have a team of three. The work breakdown is shown as follows:

**Member 1**: Plane estimation; Homography estimation;

**Member 2**: Image classification; Road structure analysis

**Member 3**: API study; Software architecture design; GIS/video/visualization code design. 

Schedule
========
**Nov 6 – Nov 17**: Image data collection; Plane estimation, homography estimation; image classification algorithm prototyping. API study and test.

**Nov 17 – Nov 24**: Working prototype that achieves Tier 1 goal 

**Nov 24 – Dec 1**: Working prototype that achieves Tier 2 goal 

**Dec 1 – Dec 11**:  Working software that achieves Tier3 goal

