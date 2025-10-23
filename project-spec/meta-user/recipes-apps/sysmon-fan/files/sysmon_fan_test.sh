#!/bin/sh -e

TEMP_SENSOR=/sys/bus/iio/devices/iio\:device0/in_temp160_temp_input
PWM_FAN=/sys/class/hwmon/hwmon0/pwm1

TARGET_TEMP=45
HIGH_TEMP=85
FAN_INC=8
PWM_MAX=255
PWM_OFF=1
PWM_CURRENT=1

# echo "*** Modify FAN using SYSMON Temperature Check"
# echo "***"

while true; do

   # Read Temperature to a Variable 
   # Returns a 5-digit value where 1st two digits are integer temperature
   # Pickoff only the first 2-digits
   SYSTEMPFULL=$(cat ${TEMP_SENSOR})
   CURRENT_TEMP=${SYSTEMPFULL:0:2} 
  
   # Test Variable against temperatures cases and set fan performance
   # We will need to modify this base on testing (including full thermal)

   if (( CURRENT_TEMP > HIGH_TEMP )); then
      # HIGH TEMP - RAMP AGGRESSIVELY
      PWM_CURRENT=255
   elif (( CURRENT_TEMP > TARGET_TEMP )); then
      # ABOVE TARGET - INCREASE SPEED
      PWM_CURRENT=$(( PWM_CURRENT + FAN_INC ))
      if (( PWM_CURRENT > 255 )); then   
         PWM_CURRENT=255;
      fi
   elif (( CURRENT_TEMP < TARGET_TEMP )); then
      # BELOW TARGET - DECREASE SPEED
      PWM_CURRENT=$(( PWM_CURRENT - FAN_INC ))
      if (( PWM_CURRENT < 1 )); then   
         PWM_CURRENT=1;
      fi
   fi
 
   echo $PWM_CURRENT > "$PWM_FAN"
#   echo "Temperature: ${CURRENT_TEMP}C - PWM Value: ${PWM_CURRENT}"

   # Test SYSMON and Adjust FAN Every 5-seconds
   sleep 5

done
