import React, { useState } from 'react';
import { WorkoutEntry } from '../../workoutData'; // FIX: Remove the .ts extension

// Define props for the form: it receives a function from the parent
interface WorkoutFormProps {
    onAddSet: (newEntry: WorkoutEntry) => void;
}

// Define the initial shape for a new workout entry
const initialFormState = {
  date: new Date().toISOString().slice(0, 10), // Default to today's date in YYYY-MM-DD format
  exercise: '',
  weightLbs: 0,
  reps: 0,
  muscleGroup: '',
  notes: '',
  set: 1, // Defaulting Set to 1 for new inputs
};

const WorkoutForm: React.FC<WorkoutFormProps> = ({ onAddSet }) => {
  const [formData, setFormData] = useState(initialFormState);

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const { name, value, type } = e.target;
    setFormData(prevData => ({
      ...prevData,
      [name]: type === 'number' ? Number(value) : value,
    }));
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault(); 

    // Simple validation
    if (!formData.exercise || !formData.weightLbs || !formData.reps) {
      alert('Please fill in Exercise, Weight, and Reps.');
      return;
    }

    // Convert formData to the WorkoutEntry type (Set is hardcoded to 1 for now)
    const newEntry: WorkoutEntry = {
        ...formData,
        set: formData.set, // Use the default set of 1
    };
    
    // 💥 The KEY ACTION: Call the function passed from the parent (page.tsx)
    onAddSet(newEntry); 

    // Reset the form after submission
    setFormData(initialFormState);
  };

  return (
    <div className="bg-white p-6 rounded-xl shadow-lg border border-gray-200">
      <h2 className="text-2xl font-bold text-gray-800 mb-6">Log New Workout Set</h2>
      <form onSubmit={handleSubmit} className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        
        {/* Date Input */}
        <div>
          <label htmlFor="date" className="block text-sm font-medium text-gray-700">Date</label>
          <input 
            type="date" 
            name="date" 
            id="date" 
            value={formData.date}
            onChange={handleChange}
            className="mt-1 block w-full rounded-md border-gray-300 shadow-sm p-2 border" 
          />
        </div>

        {/* Exercise Input */}
        <div>
          <label htmlFor="exercise" className="block text-sm font-medium text-gray-700">Exercise</label>
          <input 
            type="text" 
            name="exercise" 
            id="exercise" 
            value={formData.exercise}
            onChange={handleChange}
            className="mt-1 block w-full rounded-md border-gray-300 shadow-sm p-2 border" 
            placeholder="e.g., Overhead Press"
          />
        </div>
        
        {/* Weight Input */}
        <div>
          <label htmlFor="weightLbs" className="block text-sm font-medium text-gray-700">Weight (lbs)</label>
          <input 
            type="number" 
            name="weightLbs" 
            id="weightLbs" 
            value={formData.weightLbs || ''} // Use empty string to avoid 0 placeholder
            onChange={handleChange}
            className="mt-1 block w-full rounded-md border-gray-300 shadow-sm p-2 border" 
          />
        </div>

        {/* Reps Input */}
        <div>
          <label htmlFor="reps" className="block text-sm font-medium text-gray-700">Reps</label>
          <input 
            type="number" 
            name="reps" 
            id="reps" 
            value={formData.reps || ''}
            onChange={handleChange}
            className="mt-1 block w-full rounded-md border-gray-300 shadow-sm p-2 border" 
          />
        </div>

        {/* Muscle Group Input */}
        <div className="md:col-span-2">
          <label htmlFor="muscleGroup" className="block text-sm font-medium text-gray-700">Muscle Group</label>
          <input 
            type="text" 
            name="muscleGroup" 
            id="muscleGroup" 
            value={formData.muscleGroup}
            onChange={handleChange}
            className="mt-1 block w-full rounded-md border-gray-300 shadow-sm p-2 border" 
            placeholder="e.g., Shoulders"
          />
        </div>

        {/* Notes Input */}
        <div className="md:col-span-2">
          <label htmlFor="notes" className="block text-sm font-medium text-gray-700">Notes (Optional)</label>
          <input 
            type="text" 
            name="notes" 
            id="notes" 
            value={formData.notes}
            onChange={handleChange}
            className="mt-1 block w-full rounded-md border-gray-300 shadow-sm p-2 border" 
            placeholder="e.g., Felt easy!"
          />
        </div>

        {/* Submit Button */}
        <div className="lg:col-span-4 flex justify-end mt-4">
          <button
            type="submit"
            className="px-6 py-2 bg-indigo-600 text-white font-semibold rounded-lg shadow-md hover:bg-indigo-700 transition-colors"
          >
            Add Set
          </button>
        </div>
      </form>
    </div>
  );
};

export default WorkoutForm;