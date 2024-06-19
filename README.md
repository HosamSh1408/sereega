# EEG Data Generation and Analysis

This project generates and visualizes EEG scalp data with various components, including muscle artifacts, blink artifacts, cognitive components, and background noise. The data is then visualized using EEGLAB.

## Files

- `HArtMuT_mix_Colin27_small.mat`: Contains the head model data.

## Code Structure

1. **Load Head Model**
   ```matlab
   load('HArtMuT_mix_Colin27_small.mat');
   ```

2. **Configuration**
   Define the configuration for the EEG epochs.
   ```matlab
   epochs = struct('n', 100, 'length', 1000, 'srate', 1000); 
   ```

3. **Load Forward Model**
   Load the forward model using the head model data.
   ```matlab
   forwardModel = lf_generate_fromhartmut('mix_Colin27_small', 'montage', 'S64');
   ```

4. **Define Muscle Artifact**
   Define the muscle artifact signal properties.
   ```matlab
   muscleSignal = struct('type', 'erp', ...
                         'peakLatency', 50, ... 
                         'peakWidth',  30, ...
                         'peakAmplitude',  10 + 5*randn(), ...
                         'peakLatencyDv', 10, ...  
                         'peakWidthDv', 6, ...        
                         'peakAmplitudeDv', 2, ... 
                         'frequency', 20 + 5*randn(), ... 
                         'probability', 0.2, ...
                         'probabilitySlope', 0); 
   muscleSignal = utl_check_class(muscleSignal, 'type', 'erp'); 
   ```

5. **Define Blink Artifact**
   Define the blink artifact signal using a helper function.
   ```matlab
   blinkSignal = defineERP(50, 50, 30 + 10*randn(), 0.4); 
   ```

6. **Define Cognitive Components (P3a, P3b)**
   Define the cognitive components P3a and P3b signals.
   ```matlab
   p3aSignal = defineERP(300 + 20*randn(), 150, 8 + 2*randn(), 1);     
   p3bSignal = defineERP(400 + 30*randn(), 150, 8 + 2*randn(), 1);    
   ```

7. **Define Background Noise**
   Define the background noise signals.
   ```matlab
   noiseSignal = struct('type', 'noise', 'color', 'brown', 'amplitude', 0.1, 'probability', 1, 'probabilitySlope', 0);
   noiseSignal = noise_check_class(noiseSignal);

   noiseSignalBrain = struct('type', 'noise', 'color', 'brown-unif', 'amplitude', .05, 'probability', 1, 'probabilitySlope', 0);
   noiseSignalBrain = noise_check_class(noiseSignalBrain);
   ```

8. **Define Channel-Specific Noise**
   Define noise applied to specific brain regions.
   ```matlab
   channelNoise = struct('source', lf_get_source_middle(forwardModel, 'region', {'brain.*'}), ...
                         'signal', {{noiseSignalBrain}});
   ```

9. **Component Definition with Anatomical Considerations**
   Define all components with their anatomical sources and signals.
   ```matlab
   components = {
       % Muscle artifact 
       struct('source', lf_get_source_random(forwardModel, 'region', {'Muscle_OrbicularisOculi'}), ... 
              'signal', {{muscleSignal}})
       
       % Blink artifacts 
       struct('source', [lf_get_source_middle(forwardModel, 'region', {'EyeCornea_left_vertical'}), ...
                         lf_get_source_middle(forwardModel, 'region', {'EyeCornea_right_vertical'})], ...
              'signal', {{blinkSignal}})
       
       % Noise (Global)
       struct('source', lf_get_source_all(forwardModel), ...
              'signal', {{noiseSignal}}) 
       
       % Brain noise (Applied to brain regions)
       struct('source', lf_get_source_random(forwardModel, 'region', {'brain.*'}), ...
              'signal', {{noiseSignalBrain}})
       
       % P3a (More focused source)
       struct('source', [lf_get_source_middle(forwardModel, 'region', {'Brain_Left_Insular_Cortex'}), ...
                         lf_get_source_middle(forwardModel, 'region', {'Brain_Right_Insular_Cortex'})], ... 
              'signal', {{p3aSignal}})
       
       % P3b (More focused source)
       struct('source', [lf_get_source_middle(forwardModel, 'region', {'Brain_Left_Insular_Cortex'}), ...
                         lf_get_source_middle(forwardModel, 'region', {'Brain_Right_Insular_Cortex'})], ...
              'signal', {{p3bSignal}})
   };
   ```

10. **Data Generation and Visualization**
    Generate the scalp data and visualize it using EEGLAB.
    ```matlab
    % Create and validate components 
    validatedComponents = [];
    for i = 1:length(components)
        validatedComponents = [validatedComponents; utl_check_component(components{i}, forwardModel)];
    end

    % Generate scalp data
    data = generate_scalpdata(validatedComponents, forwardModel, epochs);

    % Create EEGLAB dataset
    EEG = utl_create_eeglabdataset(data, epochs, forwardModel);

    % Analysis: Plot EEG data
    pop_eegplot(EEG, 1, 0, 0); 
    ```

11. **Helper Function**
    Define a helper function to create ERP signals.
    ```matlab
    function signal = defineERP(peakLatency, peakWidth, peakAmplitude, probability)
        signal = struct('type', 'erp', ...
                        'peakLatency', peakLatency, ...
                        'peakWidth', peakWidth, ...
                        'peakAmplitude', peakAmplitude, ...
                        'peakLatencyDv', peakLatency * 0.2, ... % 20% deviation
                        'peakWidthDv', peakWidth * 0.2, ...       % 20% deviation
                        'peakAmplitudeDv', peakAmplitude * 0.2, ... % 20% deviation
                        'probability', probability, ...
                        'probabilitySlope', 0);
        signal = utl_check_class(signal, 'type', 'erp');
    end
    ```

## Requirements

- MATLAB
- EEGLAB toolbox
- HArtMuT head model data file (`HArtMuT_mix_Colin27_small.mat`)

## Usage

1. Load the head model data.
2. Configure the EEG epochs.
3. Load the forward model.
4. Define the muscle artifact, blink artifact, cognitive components, and background noise.
5. Define channel-specific noise.
6. Define all components with their anatomical sources and signals.
7. Generate the scalp data.
8. Create an EEGLAB dataset.
9. Visualize the EEG data using EEGLAB.

## License

This project is licensed under the MIT License - see the LICENSE file for details.