import json, os
from flask import Flask, jsonify, request
import cv2 as cv
import cmath, numpy as np, math
from PIL import Image

begin = 'first'
end = 'second'
drone=0
distance =5
aperture = 3
upper =150
lower =50
x_cords=[]
y_cords=[]
x=1

#this is for getting the rgb of the original image
rgb=[]

#biggie cheese is the number of points on an image that have 
#neighbors farther than the minimum distance
biggie_cheese = 0

#shorty is the number of points on an image that have 
#neighbors closer than the minimum distance
shorty = 0

app = Flask(__name__)

def formula(x1, x2, y1, y2):
    #distance formula
    return math.sqrt((x2 - x1) ** 2 + (y2 - y1) ** 2)

def color_keeper(image1,image2):
    #this function changes the color of coordinates that are close
    try:
        for i in range(len(x_cords)):
                    rgb.append(image1[y_cords[i],x_cords[i]])
    except Exception as e:
                print('your problems is this: ',e)
    finally:
        print('RGB values: '+str(len(rgb)))
        img = cv.imread(image2)
        for j in range(len(rgb)):
             img[y_cords[j],x_cords[j]]=rgb[j]
        cv.imwrite('edges'+str(x)+'.jpg',img)


def buddies(image):
    img =cv.imread(image)

    global biggie_cheese
    global shorty

    #clearing the variables 
    biggie_cheese -= biggie_cheese
    shorty -= shorty
    
    for z in range(len(x_cords)):
        if(z>=len(x_cords)-1):
            pass
        else:
            try:
                if(distance>formula(x_cords[z], x_cords[z+1], y_cords[z], y_cords[z+1])):
                    shorty +=1
                else:
                    biggie_cheese +=1
            except Exception as e:
                print('your problems is that: ',e)

    print('Drones closer than the minimum distance: '+str(shorty))
    print('Drones farther than the minimum distance: '+str(biggie_cheese))

@app.route('/', methods = ['GET', 'POST'])

def nameRoute():
    global begin
    global end
    global x
    global drone
    global distance
    global aperture
    global upper
    global lower
    global x_cords
    global y_cords

    if(request.method == 'POST'):
        request_data = request.data
        request_data = json.loads(request_data.decode('utf-8'))
        if('first' in request_data):
            name = request_data['first']
            begin = name
            img = cv.imread(begin)
            t_lower = lower  # Lower Threshold
            t_upper = upper  # Upper threshold
            aperture_size = aperture  # Aperture size
            
            # Applying the Canny Edge filter 
            # with Aperture Size and L2Gradient
            edge = cv.Canny(img, t_lower, 
                            t_upper,apertureSize = aperture_size, 
                            L2gradient = True )  
            x_axis = int(edge.shape[0])
            y_axis = int(edge.shape[1])
            end ='edges'+str(x)+'.jpg'
            cv.imwrite('edges'+str(x)+'.jpg',edge)
            if(x>1):
                os.remove('edges'+str(x-1)+'.jpg')
            elif(x==1):
                pass

            #this is for finding all the white pixel coordiantes
            #in the edge detected image
            try:
                for i in range(x_axis):
                    for j  in range(y_axis):
                        if(edge[i,j]== 255):
                            y_cords.append(i)
                            x_cords.append(j)
            except Exception as e:
                print('your problems is: ',e)
            finally:
                buddies(end)
                color_keeper(img,end)
            x+=1
            y_cords.clear()
            x_cords.clear()
            rgb.clear()
            return begin
        if('droneTotal' in request_data):
            numbers = request_data['droneTotal']
            drone = numbers
            return str(drone)
        if('distance' in request_data):
            space = request_data['distance']
            distance = space
            return str(distance)
        if('aperture' in request_data):
            tone = request_data['aperture']
            aperture = tone
            return str(aperture)
        if('upper' in request_data):
            higher = request_data['upper']
            upper = higher
            return str(upper)
        if('lower' in request_data):
            downer = request_data['lower']
            lower = downer
            return str(lower)
        return begin
    if(request.method == 'GET'):
        return jsonify(
            {'first' : begin,
            'second' : end,
            'droneTotal': drone,
            'distance' : distance,
            'aperture' : aperture,
            'upper' : upper,
            'lower' : lower,})   



    return jsonify(
        {'first' : begin,
        'second' : end,
        'droneTotal': drone,
        'distance' : distance,
        'aperture' : aperture,
        'upper' : upper,
        'lower' : lower,})  
         


if __name__ =="__main__":
    app.run(debug = True)